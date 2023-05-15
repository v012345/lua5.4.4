/*
** $Id: lvm.c $
** Lua virtual machine
** See Copyright Notice in lua.h
*/

#define lvm_c
#define LUA_CORE

#include "lprefix.h"

#include <float.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"

#include "ldebug.h"
#include "ldo.h"
#include "lfunc.h"
#include "lgc.h"
#include "lobject.h"
#include "lopcodes.h"
#include "lstate.h"
#include "lstring.h"
#include "ltable.h"
#include "ltm.h"
#include "lvm.h"

/*
** By default, use jump tables in the main interpreter loop on gcc
** and compatible compilers.
*/
#if !defined(LUA_USE_JUMPTABLE)
#if defined(__GNUC__)
#define LUA_USE_JUMPTABLE 1
#else
#define LUA_USE_JUMPTABLE 0
#endif
#endif

/* limit for table tag-method chains (to avoid infinite loops) */
#define MAXTAGLOOP 2000

/*
** 'l_intfitsf' checks whether a given integer is in the range that
** can be converted to a float without rounding. Used in comparisons.
*/

/* number of bits in the mantissa of a float */
#define NBM (l_floatatt(MANT_DIG))

/*
** Check whether some integers may not fit in a float, testing whether
** (maxinteger >> NBM) > 0. (That implies (1 << NBM) <= maxinteger.)
** (The shifts are done in parts, to avoid shifting by more than the size
** of an integer. In a worst case, NBM == 113 for long double and
** sizeof(long) == 32.)
*/
#if ((((LUA_MAXINTEGER >> (NBM / 4)) >> (NBM / 4)) >> (NBM / 4)) >> (NBM - (3 * (NBM / 4)))) > 0

/* limit for integers that fit in a float */
#define MAXINTFITSF ((lua_Unsigned)1 << NBM)

/* check whether 'i' is in the interval [-MAXINTFITSF, MAXINTFITSF] */
#define l_intfitsf(i) ((MAXINTFITSF + l_castS2U(i)) <= (2 * MAXINTFITSF))

#else /* all integers fit in a float precisely */

#define l_intfitsf(i) 1

#endif

/*
** Try to convert a value from string to a number value.
** If the value is not a string or is a string not representing
** a valid numeral (or if coercions from strings to numbers
** are disabled via macro 'cvt2num'), do not modify 'result'
** and return 0.
*/
static int l_strton(const TValue* obj, TValue* result) {
    lua_assert(obj != result);
    if (!cvt2num(obj)) /* is object not a string? */
        return 0;
    else
        return (luaO_str2num(svalue(obj), result) == vslen(obj) + 1);
}

/*
** Try to convert a value to a float. The float case is already handled
** by the macro 'tonumber'.
*/
int luaV_tonumber_(const TValue* obj, lua_Number* n) {
    TValue v;
    if (ttisinteger(obj)) {
        *n = cast_num(ivalue(obj));
        return 1;
    } else if (l_strton(obj, &v)) { /* string coercible to number? */
        *n = nvalue(&v); /* convert result of 'luaO_str2num' to a float */
        return 1;
    } else
        return 0; /* conversion failed */
}

/// @brief 根据 mode 把浮点数转化为整数
/// try to convert a float to an integer, rounding according to 'mode'.
int luaV_flttointeger(lua_Number n, lua_Integer* p, F2Imod mode) {
    lua_Number f = l_floor(n);
    if (n != f) { /* not an integral value? */
        if (mode == F2Ieq)
            return 0; /* fails if mode demands integral value */
        else if (mode == F2Iceil) /* needs ceil? */
            f += 1; /* convert floor to ceil (remember: n != f) */
    }
    return lua_numbertointeger(f, p);
}

/*
** try to convert a value to an integer, rounding according to 'mode',
** without string coercion.
** ("Fast track" handled by macro 'tointegerns'.)
*/
int luaV_tointegerns(const TValue* obj, lua_Integer* p, F2Imod mode) {
    if (ttisfloat(obj))
        return luaV_flttointeger(fltvalue(obj), p, mode);
    else if (ttisinteger(obj)) {
        *p = ivalue(obj);
        return 1;
    } else
        return 0;
}

/*
** try to convert a value to an integer.
*/
int luaV_tointeger(const TValue* obj, lua_Integer* p, F2Imod mode) {
    TValue v;
    if (l_strton(obj, &v)) /* does 'obj' point to a numerical string? */
        obj = &v; /* change it to point to its corresponding number */
    return luaV_tointegerns(obj, p, mode);
}

/// @brief  \r
/// Try to convert a 'for' limit to an integer, preserving the semantics of the loop.
/// Return true if the loop must not run; otherwise, '*p' gets the integer limit.
/// (The following explanation assumes a positive step; it is valid for negative steps mutatis mutandis.)
/// If the limit is an integer or can be converted to an integer, rounding down, that is the limit.
/// Otherwise, check whether the limit can be converted to a float. If the float is too large, clip it to LUA_MAXINTEGER.
/// If the float is too negative, the loop should not run, because any initial integer value is greater than such limit;
/// so, the function returns true to signal that. (For this latter case, no integer limit would be correct;
/// even a limit of LUA_MININTEGER would run the loop once for an initial value equal to LUA_MININTEGER.)
/// @param init 内部索引初始值
/// @param lim 内部索引终值
/// @param p
/// @param step 步长
/// @return 在初始条件下能否进入循环
static int forlimit(lua_State* L, lua_Integer init, const TValue* lim, lua_Integer* p, lua_Integer step) {
    if (!luaV_tointeger(lim, p, (step < 0 ? F2Iceil : F2Ifloor))) {
        /* not coercible to in integer */
        lua_Number flim; /* try to convert to float */
        if (!tonumber(lim, &flim)) /* cannot convert to float? */
            luaG_forerror(L, lim, "limit");
        /* else 'flim' is a float out of integer bounds */
        if (luai_numlt(0, flim)) { /* if it is positive, it is too large */
            if (step < 0) return 1; /* initial value must be less than it */
            *p = LUA_MAXINTEGER; /* truncate */
        } else { /* it is less than min integer */
            if (step > 0) return 1; /* initial value must be greater than it */
            *p = LUA_MININTEGER; /* truncate */
        }
    }
    return (step > 0 ? init > *p : init < *p); /* not to run? */
}

/*
** Prepare a numerical for loop (opcode OP_FORPREP).
** Return true to skip the loop. Otherwise,
** after preparation, stack will be as follows:
**   ra : internal index (safe copy of the control variable)
**   ra + 1 : loop counter (integer loops) or limit (float loops)
**   ra + 2 : step
**   ra + 3 : control variable
*/
static int forprep(lua_State* L, StkId ra) {
    TValue* pinit = s2v(ra); // 内部索引的初始值
    TValue* plimit = s2v(ra + 1); // 内部索引的终值
    TValue* pstep = s2v(ra + 2); // 内部索引的步长
    if (ttisinteger(pinit) && ttisinteger(pstep)) { /* integer loop? */
        lua_Integer init = ivalue(pinit); // 内部索引的初始值
        lua_Integer step = ivalue(pstep); // 内部索引的步长
        lua_Integer limit;
        if (step == 0) // 0 步长直接报错, 但是如果是函数返回的 0 呢?
            luaG_runerror(L, "'for' step is zero");
        // forbody 内部使用的内部索引的复制
        setivalue(s2v(ra + 3), init); /* control variable */
        if (forlimit(L, init, plimit, &limit, step))
            return 1; /* skip the loop */
        else { /* prepare loop counter */
            lua_Unsigned count;
            if (step > 0) { /* ascending loop? */
                count = l_castS2U(limit) - l_castS2U(init);
                if (step != 1) /* avoid division in the too common case */
                    count /= l_castS2U(step);
            } else { /* step < 0; descending loop */
                count = l_castS2U(init) - l_castS2U(limit);
                /* 'step+1' avoids negating 'mininteger' */
                count /= l_castS2U(-(step + 1)) + 1u;
            }
            /* store the counter in place of the limit (which won't be
               needed anymore) */
            setivalue(plimit, l_castU2S(count));
        }
    } else { /* try making all values floats */
        lua_Number init;
        lua_Number limit;
        lua_Number step;
        if (l_unlikely(!tonumber(plimit, &limit))) luaG_forerror(L, plimit, "limit");
        if (l_unlikely(!tonumber(pstep, &step))) luaG_forerror(L, pstep, "step");
        if (l_unlikely(!tonumber(pinit, &init))) luaG_forerror(L, pinit, "initial value");
        if (step == 0) luaG_runerror(L, "'for' step is zero");
        if (luai_numlt(0, step) ? luai_numlt(limit, init) : luai_numlt(init, limit))
            return 1; /* skip the loop */
        else {
            /* make sure internal values are all floats */
            setfltvalue(plimit, limit);
            setfltvalue(pstep, step);
            setfltvalue(s2v(ra), init); /* internal index */
            setfltvalue(s2v(ra + 3), init); /* control variable */
        }
    }
    return 0;
}

/*
** Execute a step of a float numerical for loop, returning
** true iff the loop must continue. (The integer case is
** written online with opcode OP_FORLOOP, for performance.)
*/
static int floatforloop(StkId ra) {
    lua_Number step = fltvalue(s2v(ra + 2));
    lua_Number limit = fltvalue(s2v(ra + 1));
    lua_Number idx = fltvalue(s2v(ra)); /* internal index */
    idx = luai_numadd(L, idx, step); /* increment index */
    if (luai_numlt(0, step) ? luai_numle(idx, limit) : luai_numle(limit, idx)) {
        chgfltvalue(s2v(ra), idx); /* update internal index */
        setfltvalue(s2v(ra + 3), idx); /* and control variable */
        return 1; /* jump back */
    } else
        return 0; /* finish the loop */
}

/// @brief 顺着元表链找, val 为最后返回的值 \r
/// Finish the table access 'val = t[key]'.
/// If 'slot' is NULL, 't' is not a table; otherwise, 'slot' points to t[k] entry (which must be empty).
void luaV_finishget(lua_State* L, const TValue* t, TValue* key, StkId val, const TValue* slot) {
    int loop; /* counter to avoid infinite loops */
    const TValue* tm; /* metamethod */
    for (loop = 0; loop < MAXTAGLOOP; loop++) {
        if (slot == NULL) { /* 't' is not a table? */
            lua_assert(!ttistable(t));
            tm = luaT_gettmbyobj(L, t, TM_INDEX);
            if (l_unlikely(notm(tm))) //
                luaG_typeerror(L, t, "index"); /* no metamethod */
            /* else will try the metamethod */
        } else { /* 't' is a table */
            lua_assert(isempty(slot));
            tm = fasttm(L, hvalue(t)->metatable, TM_INDEX); /* table's metamethod */
            if (tm == NULL) { /* no metamethod? */
                setnilvalue(s2v(val)); /* result is nil */
                return;
            }
            /* else will try the metamethod */
        }
        if (ttisfunction(tm)) { /* is metamethod a function? */
            luaT_callTMres(L, tm, t, key, val); /* call it */
            return;
        }
        t = tm; /* else try to access 'tm[key]' */
        if (luaV_fastget(L, t, key, slot, luaH_get)) { /* fast track? */
            setobj2s(L, val, slot); /* done */
            return;
        }
        /* else repeat (tail call 'luaV_finishget') */
    }
    luaG_runerror(L, "'__index' chain too long; possible loop");
}

/// @brief 会触发元方法, 如果有的话. \r
/// Finish a table assignment 't[key] = val'.
/// If 'slot' is NULL, 't' is not a table.  Otherwise, 'slot' points
/// to the entry 't[key]', or to a value with an absent key if there
/// is no such entry.  (The value at 'slot' must be empty, otherwise
/// 'luaV_fastget' would have done the job.)
void luaV_finishset(lua_State* L, const TValue* t, TValue* key, TValue* val, const TValue* slot) {
    int loop; /* counter to avoid infinite loops */
    for (loop = 0; loop < MAXTAGLOOP; loop++) {
        const TValue* tm; /* '__newindex' metamethod */
        if (slot != NULL) { /* is 't' a table? */
            Table* h = hvalue(t); /* save 't' table */
            lua_assert(isempty(slot)); /* slot must be empty */
            tm = fasttm(L, h->metatable, TM_NEWINDEX); /* get metamethod */
            if (tm == NULL) { /* no metamethod? */
                luaH_finishset(L, h, key, slot, val); /* set new value */
                invalidateTMcache(h);
                luaC_barrierback(L, obj2gco(h), val);
                return;
            }
            /* else will try the metamethod */
        } else { /* not a table; check metamethod */
            tm = luaT_gettmbyobj(L, t, TM_NEWINDEX);
            if (l_unlikely(notm(tm))) luaG_typeerror(L, t, "index");
        }
        /* try the metamethod */
        if (ttisfunction(tm)) {
            luaT_callTM(L, tm, t, key, val);
            return;
        }
        t = tm; /* else repeat assignment over 'tm' */
        if (luaV_fastget(L, t, key, slot, luaH_get)) {
            luaV_finishfastset(L, t, slot, val);
            return; /* done */
        }
        /* else 'return luaV_finishset(L, t, key, val, slot)' (loop) */
    }
    luaG_runerror(L, "'__newindex' chain too long; possible loop");
}

/*
** Compare two strings 'ls' x 'rs', returning an integer less-equal-
** -greater than zero if 'ls' is less-equal-greater than 'rs'.
** The code is a little tricky because it allows '\0' in the strings
** and it uses 'strcoll' (to respect locales) for each segments
** of the strings.
*/
static int l_strcmp(const TString* ls, const TString* rs) {
    const char* l = getstr(ls);
    size_t ll = tsslen(ls);
    const char* r = getstr(rs);
    size_t lr = tsslen(rs);
    for (;;) { /* for each segment */
        int temp = strcoll(l, r);
        if (temp != 0) /* not equal? */
            return temp; /* done */
        else { /* strings are equal up to a '\0' */
            size_t len = strlen(l); /* index of first '\0' in both strings */
            if (len == lr) /* 'rs' is finished? */
                return (len == ll) ? 0 : 1; /* check 'ls' */
            else if (len == ll) /* 'ls' is finished? */
                return -1; /* 'ls' is less than 'rs' ('rs' is not finished) */
            /* both strings longer than 'len'; go on comparing after the '\0' */
            len++;
            l += len;
            ll -= len;
            r += len;
            lr -= len;
        }
    }
}

/*
** Check whether integer 'i' is less than float 'f'. If 'i' has an
** exact representation as a float ('l_intfitsf'), compare numbers as
** floats. Otherwise, use the equivalence 'i < f <=> i < ceil(f)'.
** If 'ceil(f)' is out of integer range, either 'f' is greater than
** all integers or less than all integers.
** (The test with 'l_intfitsf' is only for performance; the else
** case is correct for all values, but it is slow due to the conversion
** from float to int.)
** When 'f' is NaN, comparisons must result in false.
*/
l_sinline int LTintfloat(lua_Integer i, lua_Number f) {
    if (l_intfitsf(i))
        return luai_numlt(cast_num(i), f); /* compare them as floats */
    else { /* i < f <=> i < ceil(f) */
        lua_Integer fi;
        if (luaV_flttointeger(f, &fi, F2Iceil)) /* fi = ceil(f) */
            return i < fi; /* compare them as integers */
        else /* 'f' is either greater or less than all integers */
            return f > 0; /* greater? */
    }
}

/*
** Check whether integer 'i' is less than or equal to float 'f'.
** See comments on previous function.
*/
l_sinline int LEintfloat(lua_Integer i, lua_Number f) {
    if (l_intfitsf(i))
        return luai_numle(cast_num(i), f); /* compare them as floats */
    else { /* i <= f <=> i <= floor(f) */
        lua_Integer fi;
        if (luaV_flttointeger(f, &fi, F2Ifloor)) /* fi = floor(f) */
            return i <= fi; /* compare them as integers */
        else /* 'f' is either greater or less than all integers */
            return f > 0; /* greater? */
    }
}

/*
** Check whether float 'f' is less than integer 'i'.
** See comments on previous function.
*/
l_sinline int LTfloatint(lua_Number f, lua_Integer i) {
    if (l_intfitsf(i))
        return luai_numlt(f, cast_num(i)); /* compare them as floats */
    else { /* f < i <=> floor(f) < i */
        lua_Integer fi;
        if (luaV_flttointeger(f, &fi, F2Ifloor)) /* fi = floor(f) */
            return fi < i; /* compare them as integers */
        else /* 'f' is either greater or less than all integers */
            return f < 0; /* less? */
    }
}

/*
** Check whether float 'f' is less than or equal to integer 'i'.
** See comments on previous function.
*/
l_sinline int LEfloatint(lua_Number f, lua_Integer i) {
    if (l_intfitsf(i))
        return luai_numle(f, cast_num(i)); /* compare them as floats */
    else { /* f <= i <=> ceil(f) <= i */
        lua_Integer fi;
        if (luaV_flttointeger(f, &fi, F2Iceil)) /* fi = ceil(f) */
            return fi <= i; /* compare them as integers */
        else /* 'f' is either greater or less than all integers */
            return f < 0; /* less? */
    }
}

/*
** Return 'l < r', for numbers.
*/
l_sinline int LTnum(const TValue* l, const TValue* r) {
    lua_assert(ttisnumber(l) && ttisnumber(r));
    if (ttisinteger(l)) {
        lua_Integer li = ivalue(l);
        if (ttisinteger(r))
            return li < ivalue(r); /* both are integers */
        else /* 'l' is int and 'r' is float */
            return LTintfloat(li, fltvalue(r)); /* l < r ? */
    } else {
        lua_Number lf = fltvalue(l); /* 'l' must be float */
        if (ttisfloat(r))
            return luai_numlt(lf, fltvalue(r)); /* both are float */
        else /* 'l' is float and 'r' is int */
            return LTfloatint(lf, ivalue(r));
    }
}

/*
** Return 'l <= r', for numbers.
*/
l_sinline int LEnum(const TValue* l, const TValue* r) {
    lua_assert(ttisnumber(l) && ttisnumber(r));
    if (ttisinteger(l)) {
        lua_Integer li = ivalue(l);
        if (ttisinteger(r))
            return li <= ivalue(r); /* both are integers */
        else /* 'l' is int and 'r' is float */
            return LEintfloat(li, fltvalue(r)); /* l <= r ? */
    } else {
        lua_Number lf = fltvalue(l); /* 'l' must be float */
        if (ttisfloat(r))
            return luai_numle(lf, fltvalue(r)); /* both are float */
        else /* 'l' is float and 'r' is int */
            return LEfloatint(lf, ivalue(r));
    }
}

/*
** return 'l < r' for non-numbers.
*/
static int lessthanothers(lua_State* L, const TValue* l, const TValue* r) {
    lua_assert(!ttisnumber(l) || !ttisnumber(r));
    if (ttisstring(l) && ttisstring(r)) /* both are strings? */
        return l_strcmp(tsvalue(l), tsvalue(r)) < 0;
    else
        return luaT_callorderTM(L, l, r, TM_LT);
}

/*
** Main operation less than; return 'l < r'.
*/
int luaV_lessthan(lua_State* L, const TValue* l, const TValue* r) {
    if (ttisnumber(l) && ttisnumber(r)) /* both operands are numbers? */
        return LTnum(l, r);
    else
        return lessthanothers(L, l, r);
}

/*
** return 'l <= r' for non-numbers.
*/
static int lessequalothers(lua_State* L, const TValue* l, const TValue* r) {
    lua_assert(!ttisnumber(l) || !ttisnumber(r));
    if (ttisstring(l) && ttisstring(r)) /* both are strings? */
        return l_strcmp(tsvalue(l), tsvalue(r)) <= 0;
    else
        return luaT_callorderTM(L, l, r, TM_LE);
}

/*
** Main operation less than or equal to; return 'l <= r'.
*/
int luaV_lessequal(lua_State* L, const TValue* l, const TValue* r) {
    if (ttisnumber(l) && ttisnumber(r)) /* both operands are numbers? */
        return LEnum(l, r);
    else
        return lessequalothers(L, l, r);
}

/*
** Main operation for equality of Lua values; return 't1 == t2'.
** L == NULL means raw equality (no metamethods)
*/
int luaV_equalobj(lua_State* L, const TValue* t1, const TValue* t2) {
    const TValue* tm;
    if (ttypetag(t1) != ttypetag(t2)) { /* not the same variant? */
        // 只有浮点与整数有可能在细分不同时, 但是值是等于的
        if (ttype(t1) != ttype(t2) || ttype(t1) != LUA_TNUMBER)
            return 0; /* only numbers can be equal with different variants */
        else { /* two numbers with different variants */
            /* One of them is an integer. If the other does not have an
               integer value, they cannot be equal; otherwise, compare their
               integer values. */
            lua_Integer i1, i2;
            // 看看能不能等值转化为整数, 之后看看整数是否相等
            return (luaV_tointegerns(t1, &i1, F2Ieq) && luaV_tointegerns(t2, &i2, F2Ieq) && i1 == i2);
        }
    }
    /* values have same type and same variant */
    switch (ttypetag(t1)) {
        case LUA_VNIL:
        case LUA_VFALSE:
        case LUA_VTRUE: // 这 3 种, 只要细分相同, 就相等
            return 1;
        case LUA_VNUMINT: //
            return (ivalue(t1) == ivalue(t2));
        case LUA_VNUMFLT: //
            return luai_numeq(fltvalue(t1), fltvalue(t2));
        case LUA_VLIGHTUSERDATA: //
            return pvalue(t1) == pvalue(t2);
        case LUA_VLCF: //
            return fvalue(t1) == fvalue(t2);
        case LUA_VSHRSTR: //
            return eqshrstr(tsvalue(t1), tsvalue(t2));
        case LUA_VLNGSTR: //
            return luaS_eqlngstr(tsvalue(t1), tsvalue(t2));
        case LUA_VUSERDATA: {
            if (uvalue(t1) == uvalue(t2))
                return 1;
            else if (L == NULL)
                return 0;
            tm = fasttm(L, uvalue(t1)->metatable, TM_EQ);
            if (tm == NULL) //
                tm = fasttm(L, uvalue(t2)->metatable, TM_EQ);
            break; /* will try TM */
        }
        case LUA_VTABLE: {
            if (hvalue(t1) == hvalue(t2))
                return 1;
            else if (L == NULL)
                return 0;
            tm = fasttm(L, hvalue(t1)->metatable, TM_EQ);
            if (tm == NULL) //
                tm = fasttm(L, hvalue(t2)->metatable, TM_EQ);
            break; /* will try TM */
        }
        default: return gcvalue(t1) == gcvalue(t2);
    }
    if (tm == NULL) /* no TM? */
        return 0; /* objects are different */
    else {
        luaT_callTMres(L, tm, t1, t2, L->top); /* call TM */
        return !l_isfalse(s2v(L->top));
    }
}

/* macro used by 'luaV_concat' to ensure that element at 'o' is a string */
#define tostring(L, o) (ttisstring(o) || (cvt2str(o) && (luaO_tostring(L, o), 1)))

#define isemptystr(o) (ttisshrstring(o) && tsvalue(o)->shrlen == 0)

/* copy strings in stack from top - n up to top - 1 to buffer */
static void copy2buff(StkId top, int n, char* buff) {
    size_t tl = 0; /* size already copied */
    do {
        size_t l = vslen(s2v(top - n)); /* length of string being copied */
        memcpy(buff + tl, svalue(s2v(top - n)), l * sizeof(char));
        tl += l;
    } while (--n > 0);
}

/*
** Main operation for concatenation: concat 'total' values in the stack,
** from 'L->top - total' up to 'L->top - 1'.
*/
void luaV_concat(lua_State* L, int total) {
    if (total == 1) return; /* "all" values already concatenated */
    do {
        StkId top = L->top;
        int n = 2; /* number of elements handled in this pass (at least 2) */
        if (!(ttisstring(s2v(top - 2)) || cvt2str(s2v(top - 2))) || !tostring(L, s2v(top - 1)))
            luaT_tryconcatTM(L);
        else if (isemptystr(s2v(top - 1))) /* second operand is empty? */
            cast_void(tostring(L, s2v(top - 2))); /* result is first operand */
        else if (isemptystr(s2v(top - 2))) { /* first operand is empty string? */
            setobjs2s(L, top - 2, top - 1); /* result is second op. */
        } else {
            /* at least two non-empty string values; get as many as possible */
            size_t tl = vslen(s2v(top - 1));
            TString* ts;
            /* collect total length and number of strings */
            for (n = 1; n < total && tostring(L, s2v(top - n - 1)); n++) {
                size_t l = vslen(s2v(top - n - 1));
                if (l_unlikely(l >= (MAX_SIZE / sizeof(char)) - tl)) luaG_runerror(L, "string length overflow");
                tl += l;
            }
            if (tl <= LUAI_MAXSHORTLEN) { /* is result a short string? */
                char buff[LUAI_MAXSHORTLEN];
                copy2buff(top, n, buff); /* copy strings to buffer */
                ts = luaS_newlstr(L, buff, tl);
            } else { /* long string; copy strings directly to final result */
                ts = luaS_createlngstrobj(L, tl);
                copy2buff(top, n, getstr(ts));
            }
            setsvalue2s(L, top - n, ts); /* create result */
        }
        total -= n - 1; /* got 'n' strings to create 1 new */
        L->top -= n - 1; /* popped 'n' strings and pushed one */
    } while (total > 1); /* repeat until only 1 result left */
}

/*
** Main operation 'ra = #rb'.
*/
void luaV_objlen(lua_State* L, StkId ra, const TValue* rb) {
    const TValue* tm;
    switch (ttypetag(rb)) {
        case LUA_VTABLE: {
            Table* h = hvalue(rb);
            tm = fasttm(L, h->metatable, TM_LEN);
            if (tm) // 如果表有 TM_LEN 元方法, 元方法优先
                break; /* metamethod? break switch to call it */
            setivalue(s2v(ra), luaH_getn(h)); /* else primitive len */
            return;
        }
        case LUA_VSHRSTR: { // 短字段串直接返回 shrlen
            setivalue(s2v(ra), tsvalue(rb)->shrlen);
            return;
        }
        case LUA_VLNGSTR: { // 长字段串直接返回 lnglen
            setivalue(s2v(ra), tsvalue(rb)->u.lnglen);
            return;
        }
        default: { /* try metamethod */
            tm = luaT_gettmbyobj(L, rb, TM_LEN);
            // 没有 TM_LEN 方法, 报错
            if (l_unlikely(notm(tm))) /* no metamethod? */
                luaG_typeerror(L, rb, "get length of");
            break;
        }
    }
    // 除表, 字符串, 如果数据有 TM_LEN 元方法, 调用之
    luaT_callTMres(L, tm, rb, rb, ra);
}

/*
** Integer division; return 'm // n', that is, floor(m/n).
** C division truncates its result (rounds towards zero).
** 'floor(q) == trunc(q)' when 'q >= 0' or when 'q' is integer,
** otherwise 'floor(q) == trunc(q) - 1'.
*/
lua_Integer luaV_idiv(lua_State* L, lua_Integer m, lua_Integer n) {
    if (l_unlikely(l_castS2U(n) + 1u <= 1u)) { /* special cases: -1 or 0 */
        if (n == 0) luaG_runerror(L, "attempt to divide by zero");
        return intop(-, 0, m); /* n==-1; avoid overflow with 0x80000...//-1 */
    } else {
        lua_Integer q = m / n; /* perform C division */
        if ((m ^ n) < 0 && m % n != 0) /* 'm/n' would be negative non-integer? */
            q -= 1; /* correct result for different rounding */
        return q;
    }
}

/*
** Integer modulus; return 'm % n'. (Assume that C '%' with
** negative operands follows C99 behavior. See previous comment
** about luaV_idiv.)
*/
lua_Integer luaV_mod(lua_State* L, lua_Integer m, lua_Integer n) {
    if (l_unlikely(l_castS2U(n) + 1u <= 1u)) { /* special cases: -1 or 0 */
        if (n == 0) luaG_runerror(L, "attempt to perform 'n%%0'");
        return 0; /* m % -1 == 0; avoid overflow with 0x80000...%-1 */
    } else {
        lua_Integer r = m % n;
        if (r != 0 && (r ^ n) < 0) /* 'm/n' would be non-integer negative? */
            r += n; /* correct result for different rounding */
        return r;
    }
}

/*
** Float modulus
*/
lua_Number luaV_modf(lua_State* L, lua_Number m, lua_Number n) {
    lua_Number r;
    luai_nummod(L, m, n, r);
    return r;
}

/* number of bits in an integer */
#define NBITS cast_int(sizeof(lua_Integer) * CHAR_BIT)

/*
** Shift left operation. (Shift right just negates 'y'.)
*/
#define luaV_shiftr(x, y) luaV_shiftl(x, intop(-, 0, y))

lua_Integer luaV_shiftl(lua_Integer x, lua_Integer y) {
    if (y < 0) { /* shift right? */
        if (y <= -NBITS)
            return 0;
        else
            return intop(>>, x, -y);
    } else { /* shift left */
        if (y >= NBITS)
            return 0;
        else
            return intop(<<, x, y);
    }
}

/// @brief create a new Lua closure, push it in the stack, and initialize its upvalues.
/// @param L Lua 状态机
/// @param p 函数原型指针
/// @param encup 一个指向父函数的 upvalue 数组的指针
/// @param base 当前函数的基址, 就是 func + 1
/// @param ra 返回地址的位置
static void pushclosure(lua_State* L, Proto* p, UpVal** encup, StkId base, StkId ra) {
    int nup = p->sizeupvalues; // 取函数原型的 upvalue 数量
    Upvaldesc* uv = p->upvalues; // upvalue 描述数组 uv
    int i;
    LClosure* ncl = luaF_newLclosure(L, nup); // 创建一个 Lua 闭包
    ncl->p = p; // 关联 Proto
    setclLvalue2s(L, ra, ncl); /* anchor new closure in stack */
    for (i = 0; i < nup; i++) { /* fill in its upvalues */
        if (uv[i].instack) /* upvalue refers to local variable? */
            ncl->upvals[i] = luaF_findupval(L, base + uv[i].idx);
        else /* get upvalue from enclosing function */
            ncl->upvals[i] = encup[uv[i].idx];
        luaC_objbarrier(L, ncl, ncl->upvals[i]);
    }
}

/*
** finish execution of an opcode interrupted by a yield
*/
void luaV_finishOp(lua_State* L) {
    CallInfo* ci = L->ci;
    StkId base = ci->func + 1;
    Instruction inst = *(ci->u.l.savedpc - 1); /* interrupted instruction */
    OpCode op = GET_OPCODE(inst);
    switch (op) { /* finish its execution */
        case OP_MMBIN:
        case OP_MMBINI:
        case OP_MMBINK: {
            setobjs2s(L, base + GETARG_A(*(ci->u.l.savedpc - 2)), --L->top);
            break;
        }
        case OP_UNM:
        case OP_BNOT:
        case OP_LEN:
        case OP_GETTABUP:
        case OP_GETTABLE:
        case OP_GETI:
        case OP_GETFIELD:
        case OP_SELF: {
            setobjs2s(L, base + GETARG_A(inst), --L->top);
            break;
        }
        case OP_LT:
        case OP_LE:
        case OP_LTI:
        case OP_LEI:
        case OP_GTI:
        case OP_GEI:
        case OP_EQ: { /* note that 'OP_EQI'/'OP_EQK' cannot yield */ int res = !l_isfalse(s2v(L->top - 1)); L->top--;
#if defined(LUA_COMPAT_LT_LE)
            if (ci->callstatus & CIST_LEQ) { /* "<=" using "<" instead? */
                ci->callstatus ^= CIST_LEQ; /* clear mark */
                res = !res; /* negate result */
            }
#endif
            lua_assert(GET_OPCODE(*ci->u.l.savedpc) == OP_JMP);
            if (res != GETARG_k(inst)) /* condition failed? */
                ci->u.l.savedpc++; /* skip jump instruction */
            break;
        }
        case OP_CONCAT: {
            StkId top = L->top - 1; /* top when 'luaT_tryconcatTM' was called */
            int a = GETARG_A(inst); /* first element to concatenate */
            int total = cast_int(top - 1 - (base + a)); /* yet to concatenate */
            setobjs2s(L, top - 2, top); /* put TM result in proper position */
            L->top = top - 1; /* top is one after last element (at top-2) */
            luaV_concat(L, total); /* concat them (may yield again) */
            break;
        }
        case OP_CLOSE: { /* yielded closing variables */
            ci->u.l.savedpc--; /* repeat instruction to close other vars. */
            break;
        }
        case OP_RETURN: { /* yielded closing variables */
            StkId ra = base + GETARG_A(inst);
            /* adjust top to signal correct number of returns, in case the
               return is "up to top" ('isIT') */
            L->top = ra + ci->u2.nres;
            /* repeat instruction to close other vars. and complete the return */
            ci->u.l.savedpc--;
            break;
        }
        default: {
            /* only these other opcodes can yield */
            lua_assert(op == OP_TFORCALL || op == OP_CALL || op == OP_TAILCALL || op == OP_SETTABUP || op == OP_SETTABLE || op == OP_SETI || op == OP_SETFIELD);
            break;
        }
    }
}

/*
** {==================================================================
** Macros for arithmetic/bitwise/comparison opcodes in 'luaV_execute'
** ===================================================================
*/

#define l_addi(L, a, b) intop(+, a, b)
#define l_subi(L, a, b) intop(-, a, b)
#define l_muli(L, a, b) intop(*, a, b)
#define l_band(a, b) intop(&, a, b)
#define l_bor(a, b) intop(|, a, b)
#define l_bxor(a, b) intop(^, a, b)

#define l_lti(a, b) (a < b)
#define l_lei(a, b) (a <= b)
#define l_gti(a, b) (a > b)
#define l_gei(a, b) (a >= b)

// R[A] = R[B] op sC \r
// Arithmetic operations with immediate operands. 'iop' is the integer operation, 'fop' is the float operation.
#define op_arithI(L, iop, fop)                                                                                                                                                                         \
    {                                                                                                                                                                                                  \
        TValue* v1 = vRB(i);                                                                                                                                                                           \
        int imm = GETARG_sC(i);                                                                                                                                                                        \
        if (ttisinteger(v1)) {                                                                                                                                                                         \
            lua_Integer iv1 = ivalue(v1);                                                                                                                                                              \
            pc++;                                                                                                                                                                                      \
            setivalue(s2v(ra), iop(L, iv1, imm));                                                                                                                                                      \
        } else if (ttisfloat(v1)) {                                                                                                                                                                    \
            lua_Number nb = fltvalue(v1);                                                                                                                                                              \
            lua_Number fimm = cast_num(imm);                                                                                                                                                           \
            pc++;                                                                                                                                                                                      \
            setfltvalue(s2v(ra), fop(L, nb, fimm));                                                                                                                                                    \
        }                                                                                                                                                                                              \
    }

/*
** Auxiliary function for arithmetic operations over floats and others
** with two register operands.
*/
#define op_arithf_aux(L, v1, v2, fop)                                                                                                                                                                  \
    {                                                                                                                                                                                                  \
        lua_Number n1;                                                                                                                                                                                 \
        lua_Number n2;                                                                                                                                                                                 \
        if (tonumberns(v1, n1) && tonumberns(v2, n2)) {                                                                                                                                                \
            pc++;                                                                                                                                                                                      \
            setfltvalue(s2v(ra), fop(L, n1, n2));                                                                                                                                                      \
        }                                                                                                                                                                                              \
    }

/*
** Arithmetic operations over floats and others with register operands.
*/
#define op_arithf(L, fop)                                                                                                                                                                              \
    {                                                                                                                                                                                                  \
        TValue* v1 = vRB(i);                                                                                                                                                                           \
        TValue* v2 = vRC(i);                                                                                                                                                                           \
        op_arithf_aux(L, v1, v2, fop);                                                                                                                                                                 \
    }

/*
** Arithmetic operations with K operands for floats.
*/
#define op_arithfK(L, fop)                                                                                                                                                                             \
    {                                                                                                                                                                                                  \
        TValue* v1 = vRB(i);                                                                                                                                                                           \
        TValue* v2 = KC(i);                                                                                                                                                                            \
        lua_assert(ttisnumber(v2));                                                                                                                                                                    \
        op_arithf_aux(L, v1, v2, fop);                                                                                                                                                                 \
    }

// R[A] = v1 op v2 \r
// Arithmetic operations over integers and floats.
#define op_arith_aux(L, v1, v2, iop, fop)                                                                                                                                                              \
    {                                                                                                                                                                                                  \
        if (ttisinteger(v1) && ttisinteger(v2)) {                                                                                                                                                      \
            lua_Integer i1 = ivalue(v1);                                                                                                                                                               \
            lua_Integer i2 = ivalue(v2);                                                                                                                                                               \
            pc++;                                                                                                                                                                                      \
            setivalue(s2v(ra), iop(L, i1, i2));                                                                                                                                                        \
        } else                                                                                                                                                                                         \
            op_arithf_aux(L, v1, v2, fop);                                                                                                                                                             \
    }

/*
** Arithmetic operations with register operands.
*/
#define op_arith(L, iop, fop)                                                                                                                                                                          \
    {                                                                                                                                                                                                  \
        TValue* v1 = vRB(i);                                                                                                                                                                           \
        TValue* v2 = vRC(i);                                                                                                                                                                           \
        op_arith_aux(L, v1, v2, iop, fop);                                                                                                                                                             \
    }

// R[A] = R[B] op K[C] \r
// Arithmetic operations with K operands.
#define op_arithK(L, iop, fop)                                                                                                                                                                         \
    {                                                                                                                                                                                                  \
        TValue* v1 = vRB(i);                                                                                                                                                                           \
        TValue* v2 = KC(i);                                                                                                                                                                            \
        lua_assert(ttisnumber(v2));                                                                                                                                                                    \
        op_arith_aux(L, v1, v2, iop, fop);                                                                                                                                                             \
    }

/*
** Bitwise operations with constant operand.
*/
#define op_bitwiseK(L, op)                                                                                                                                                                             \
    {                                                                                                                                                                                                  \
        TValue* v1 = vRB(i);                                                                                                                                                                           \
        TValue* v2 = KC(i);                                                                                                                                                                            \
        lua_Integer i1;                                                                                                                                                                                \
        lua_Integer i2 = ivalue(v2);                                                                                                                                                                   \
        if (tointegerns(v1, &i1)) {                                                                                                                                                                    \
            pc++;                                                                                                                                                                                      \
            setivalue(s2v(ra), op(i1, i2));                                                                                                                                                            \
        }                                                                                                                                                                                              \
    }

/*
** Bitwise operations with register operands.
*/
#define op_bitwise(L, op)                                                                                                                                                                              \
    {                                                                                                                                                                                                  \
        TValue* v1 = vRB(i);                                                                                                                                                                           \
        TValue* v2 = vRC(i);                                                                                                                                                                           \
        lua_Integer i1;                                                                                                                                                                                \
        lua_Integer i2;                                                                                                                                                                                \
        if (tointegerns(v1, &i1) && tointegerns(v2, &i2)) {                                                                                                                                            \
            pc++;                                                                                                                                                                                      \
            setivalue(s2v(ra), op(i1, i2));                                                                                                                                                            \
        }                                                                                                                                                                                              \
    }

/*
** Order operations with register operands. 'opn' actually works
** for all numbers, but the fast track improves performance for
** integers.
*/
#define op_order(L, opi, opn, other)                                                                                                                                                                   \
    {                                                                                                                                                                                                  \
        int cond;                                                                                                                                                                                      \
        TValue* rb = vRB(i);                                                                                                                                                                           \
        if (ttisinteger(s2v(ra)) && ttisinteger(rb)) {                                                                                                                                                 \
            lua_Integer ia = ivalue(s2v(ra));                                                                                                                                                          \
            lua_Integer ib = ivalue(rb);                                                                                                                                                               \
            cond = opi(ia, ib);                                                                                                                                                                        \
        } else if (ttisnumber(s2v(ra)) && ttisnumber(rb))                                                                                                                                              \
            cond = opn(s2v(ra), rb);                                                                                                                                                                   \
        else                                                                                                                                                                                           \
            Protect(cond = other(L, s2v(ra), rb));                                                                                                                                                     \
        docondjump();                                                                                                                                                                                  \
    }

/*
** Order operations with immediate operand. (Immediate operand is
** always small enough to have an exact representation as a float.)
*/
#define op_orderI(L, opi, opf, inv, tm)                                                                                                                                                                \
    {                                                                                                                                                                                                  \
        int cond;                                                                                                                                                                                      \
        int im = GETARG_sB(i);                                                                                                                                                                         \
        if (ttisinteger(s2v(ra)))                                                                                                                                                                      \
            cond = opi(ivalue(s2v(ra)), im);                                                                                                                                                           \
        else if (ttisfloat(s2v(ra))) {                                                                                                                                                                 \
            lua_Number fa = fltvalue(s2v(ra));                                                                                                                                                         \
            lua_Number fim = cast_num(im);                                                                                                                                                             \
            cond = opf(fa, fim);                                                                                                                                                                       \
        } else {                                                                                                                                                                                       \
            int isf = GETARG_C(i);                                                                                                                                                                     \
            Protect(cond = luaT_callorderiTM(L, s2v(ra), im, inv, isf, tm));                                                                                                                           \
        }                                                                                                                                                                                              \
        docondjump();                                                                                                                                                                                  \
    }

/* }================================================================== */

/*
** {==================================================================
** Function 'luaV_execute': main interpreter loop
** ===================================================================
*/

/*
** some macros for common tasks in 'luaV_execute'
*/

// 当前闭包中, 指令 i 中 A 寄存器的位置, 类型为 StkId
#define RA(i) (base + GETARG_A(i))
// 当前闭包中, 指令 i 中 B 寄存器的位置, 类型为 StkId
#define RB(i) (base + GETARG_B(i))
// 取指令 i 的 B 段指向的的寄存器中的值
#define vRB(i) s2v(RB(i))
#define KB(i) (k + GETARG_B(i))
#define RC(i) (base + GETARG_C(i))
// 取指令 i 的 C 段指向的的寄存器中的值
#define vRC(i) s2v(RC(i))
// 取常量表中索引为指令 i 的 C 段值的
#define KC(i) (k + GETARG_C(i))
// 如果指 i 的 k 段为 1, 去常量表中找, 不然去寄存器里找
#define RKC(i) ((TESTARG_k(i)) ? k + GETARG_C(i) : s2v(base + GETARG_C(i)))

#define updatetrap(ci) (trap = ci->u.l.trap)

#define updatebase(ci) (base = ci->func + 1)

#define updatestack(ci)                                                                                                                                                                                \
    {                                                                                                                                                                                                  \
        if (l_unlikely(trap)) {                                                                                                                                                                        \
            updatebase(ci);                                                                                                                                                                            \
            ra = RA(i);                                                                                                                                                                                \
        }                                                                                                                                                                                              \
    }

/*
** Execute a jump instruction. The 'updatetrap' allows signals to stop
** tight loops. (Without it, the local copy of 'trap' could never change.)
*/
#define dojump(ci, i, e)                                                                                                                                                                               \
    {                                                                                                                                                                                                  \
        pc += GETARG_sJ(i) + e;                                                                                                                                                                        \
        updatetrap(ci);                                                                                                                                                                                \
    }

/* for test instructions, execute the jump instruction that follows it */
#define donextjump(ci)                                                                                                                                                                                 \
    {                                                                                                                                                                                                  \
        Instruction ni = *pc;                                                                                                                                                                          \
        dojump(ci, ni, 1);                                                                                                                                                                             \
    }

/*
** do a conditional jump: skip next instruction if 'cond' is not what
** was expected (parameter 'k'), else do next instruction, which must
** be a jump.
*/
#define docondjump()                                                                                                                                                                                   \
    if (cond != GETARG_k(i))                                                                                                                                                                           \
        pc++;                                                                                                                                                                                          \
    else                                                                                                                                                                                               \
        donextjump(ci);

/*
** Correct global 'pc'.
*/
#define savepc(L) (ci->u.l.savedpc = pc)

/*
** Whenever code can raise errors, the global 'pc' and the global
** 'top' must be correct to report occasional errors.
*/
#define savestate(L, ci) (savepc(L), L->top = ci->top)

/*
** Protect code that, in general, can raise errors, reallocate the
** stack, and change the hooks.
*/
#define Protect(exp) (savestate(L, ci), (exp), updatetrap(ci))

/* special version that does not change the top */
#define ProtectNT(exp) (savepc(L), (exp), updatetrap(ci))

/*
** Protect code that can only raise errors. (That is, it cannot change
** the stack or hooks.)
*/
#define halfProtect(exp) (savestate(L, ci), (exp))

/* 'c' is the limit of live values in the stack */
#define checkGC(L, c)                                                                                                                                                                                  \
    {                                                                                                                                                                                                  \
        luaC_condGC(L, (savepc(L), L->top = (c)), updatetrap(ci));                                                                                                                                     \
        luai_threadyield(L);                                                                                                                                                                           \
    }

// fetch an instruction and prepare its execution
#define vmfetch()                                                                                                                                                                                      \
    {                                                                                                                                                                                                  \
        if (l_unlikely(trap)) { /* stack reallocation or hooks? */                                                                                                                                     \
            trap = luaG_traceexec(L, pc); /* handle hooks */                                                                                                                                           \
            updatebase(ci); /* correct stack */                                                                                                                                                        \
        }                                                                                                                                                                                              \
        i = *(pc++);                                                                                                                                                                                   \
        ra = RA(i); /* WARNING: any stack reallocation invalidates 'ra' */                                                                                                                             \
    }

#define vmdispatch(o) switch (o)
#define vmcase(l) case l:
#define vmbreak break

void luaV_execute(lua_State* L, CallInfo* ci) {
    LClosure* cl;
    TValue* k; // 函数的常量表, 编译过程生成
    StkId base; // 当前函数的栈底 ci->func + 1
    const Instruction* pc; // 指向要执行指令的指针
    int trap;
#if LUA_USE_JUMPTABLE
#include "ljumptab.h"
#endif
startfunc: // 开始执行 lua 函数
    trap = L->hookmask;
returning: /* trap already set */
    cl = clLvalue(s2v(ci->func)); // 根据 CallInfo 的 func 在栈中拿到 lua 闭包
    k = cl->p->k; // 拿到 lua 闭包中常量表
    pc = ci->u.l.savedpc; // 当前 CallInfo 执行到指令
    if (l_unlikely(trap)) {
        if (pc == cl->p->code) { /* first instruction (not resuming)? */
            if (cl->p->is_vararg)
                trap = 0; /* hooks will start after VARARGPREP instruction */
            else /* check 'call' hook */
                luaD_hookcall(L, ci);
        }
        ci->u.l.trap = 1; /* assume trap is on, for now */
    }
    base = ci->func + 1;
    /* 对应 83 条虚拟机指令; main loop of interpreter */
    for (;;) {
        Instruction i; /* instruction being executed */
        StkId ra; /* instruction's A register */
        // i 的 A 段就是指向函数的寄存器
        vmfetch(); // 取指令, ra 为 i 的 A 段, 同时 pc 指向下一个指令
        // ra 现在已经指向正确的寄存器啦
#if 0
        /* low-level line tracing for debugging Lua */
        printf("line: %d\n", luaG_getfuncline(cl->p, pcRel(pc, cl->p)));
#endif
        lua_assert(base == ci->func + 1);
        lua_assert(base <= L->top && L->top < L->stack_last);
        /* invalidate top for instructions not expecting it */
        lua_assert(isIT(i) || (cast_void(L->top = base), 1));
        // 指令 i 的操作码
        vmdispatch(GET_OPCODE(i)) {
            vmcase(OP_MOVE) {
                setobjs2s(L, ra, RB(i)); // R[A] := R[B]
                vmbreak;
            }
            vmcase(OP_LOADI) {
                lua_Integer b = GETARG_sBx(i);
                setivalue(s2v(ra), b); // R[A] := sBx
                vmbreak;
            }
            vmcase(OP_LOADF) { // 当浮点数与整数可以恒等转换时, 使用些指令
                int b = GETARG_sBx(i); // 当浮点数放到 sBx 中, 取出之后, 再转为浮点数
                setfltvalue(s2v(ra), cast_num(b)); // R[A] := (lua_Number)sBx
                vmbreak;
            }
            vmcase(OP_LOADK) { // 常量表中的值放到 A 寄存器中
                TValue* rb = k + GETARG_Bx(i); // Bx 存放着常量表的索引
                setobj2s(L, ra, rb); // R[A] := K[Bx]
                vmbreak;
            }
            vmcase(OP_LOADKX) { // 需要额外参数
                TValue* rb;
                rb = k + GETARG_Ax(*pc); // pc 现在是额外参数
                pc++; // 跳过被当作额外参数的指令
                setobj2s(L, ra, rb); // R[A] := K[extra arg]
                vmbreak;
            }
            vmcase(OP_LOADFALSE) {
                setbfvalue(s2v(ra)); // R[A] := false
                vmbreak;
            }
            vmcase(OP_LFALSESKIP) { // 要跳过下一条指令
                setbfvalue(s2v(ra)); // R[A] := false
                pc++; /* skip next instruction */
                vmbreak;
            }
            vmcase(OP_LOADTRUE) {
                setbtvalue(s2v(ra)); // R[A] := true
                vmbreak;
            }
            vmcase(OP_LOADNIL) { // 从 ra 开始, 之后的 b 个寄存器置 nil
                int b = GETARG_B(i); // b 为指令 i 的 B 段(无符号)
                do { // R[A], R[A+1], ..., R[A+B] := nil
                    setnilvalue(s2v(ra++));
                } while (b--);
                vmbreak;
            }
            vmcase(OP_GETUPVAL) { // 从 upvalue 中取值
                int b = GETARG_B(i); // b 为指令 i 的 B 段(无符号), upvalue 的索引
                setobj2s(L, ra, cl->upvals[b]->v); // R[A] := UpValue[B]
                vmbreak;
            }
            vmcase(OP_SETUPVAL) { // 设置 upvalue 的值
                UpVal* uv = cl->upvals[GETARG_B(i)];
                setobj(L, uv->v, s2v(ra)); // 把 ra 指向的值赋值给 upvalue
                luaC_barrier(L, uv, s2v(ra));
                vmbreak;
            }
            vmcase(OP_GETTABUP) { // R[A] := UpValue[B][K[C]:string]
                const TValue* slot;
                // B 为 upvalue 的索引
                TValue* upval = cl->upvals[GETARG_B(i)]->v; // 一个表
                TValue* rc = KC(i); // C 为常量表的索引
                TString* key = tsvalue(rc); /* key must be a string */
                if (luaV_fastget(L, upval, key, slot, luaH_getshortstr)) {
                    // 如果如表 upval 的 key 的值不为空, 把值赋给 ra
                    setobj2s(L, ra, slot);
                } else
                    // 看看可不可以通过元表来设置 ra
                    Protect(luaV_finishget(L, upval, rc, ra, slot));
                vmbreak;
            }
            vmcase(OP_GETTABLE) { // R[A] := R[B][R[C]]
                const TValue* slot;
                TValue* rb = vRB(i); // 表
                TValue* rc = vRC(i); // 键
                lua_Unsigned n;
                if (ttisinteger(rc) /* fast track for integers? */
                        ? (cast_void(n = ivalue(rc)), luaV_fastgeti(L, rb, n, slot))
                        : luaV_fastget(L, rb, rc, slot, luaH_get)) {
                    setobj2s(L, ra, slot);
                } else
                    Protect(luaV_finishget(L, rb, rc, ra, slot));
                vmbreak;
            }
            vmcase(OP_GETI) { // R[A] := R[B][C]
                const TValue* slot;
                TValue* rb = vRB(i); // 表
                int c = GETARG_C(i); // 整数键值
                if (luaV_fastgeti(L, rb, c, slot)) {
                    setobj2s(L, ra, slot);
                } else {
                    TValue key;
                    setivalue(&key, c);
                    Protect(luaV_finishget(L, rb, &key, ra, slot));
                }
                vmbreak;
            }
            vmcase(OP_GETFIELD) { // R[A] := R[B][K[C]:string]
                const TValue* slot;
                TValue* rb = vRB(i);
                TValue* rc = KC(i); // K[C]
                TString* key = tsvalue(rc); /* key must be a string */
                if (luaV_fastget(L, rb, key, slot, luaH_getshortstr)) {
                    setobj2s(L, ra, slot);
                } else
                    Protect(luaV_finishget(L, rb, rc, ra, slot));
                vmbreak;
            }
            vmcase(OP_SETTABUP) { // UpValue[A][K[B]:string] := RK(C)
                const TValue* slot;
                TValue* upval = cl->upvals[GETARG_A(i)]->v;
                TValue* rb = KB(i);
                TValue* rc = RKC(i);
                TString* key = tsvalue(rb); /* key must be a string */
                if (luaV_fastget(L, upval, key, slot, luaH_getshortstr)) {
                    luaV_finishfastset(L, upval, slot, rc);
                } else
                    Protect(luaV_finishset(L, upval, rb, rc, slot));
                vmbreak;
            }
            vmcase(OP_SETTABLE) { // R[A][R[B]] := RK(C)
                const TValue* slot;
                TValue* rb = vRB(i); /* key (table is in 'ra') */
                TValue* rc = RKC(i); /* value */
                lua_Unsigned n;
                if (ttisinteger(rb) /* fast track for integers? */
                        ? (cast_void(n = ivalue(rb)), luaV_fastgeti(L, s2v(ra), n, slot))
                        : luaV_fastget(L, s2v(ra), rb, slot, luaH_get)) {
                    luaV_finishfastset(L, s2v(ra), slot, rc);
                } else
                    Protect(luaV_finishset(L, s2v(ra), rb, rc, slot));
                vmbreak;
            }
            vmcase(OP_SETI) { // R[A][B] := RK(C)
                const TValue* slot;
                int c = GETARG_B(i);
                TValue* rc = RKC(i);
                // 表在 ra 里了
                if (luaV_fastgeti(L, s2v(ra), c, slot)) {
                    luaV_finishfastset(L, s2v(ra), slot, rc);
                } else {
                    TValue key;
                    setivalue(&key, c);
                    Protect(luaV_finishset(L, s2v(ra), &key, rc, slot));
                }
                vmbreak;
            }
            vmcase(OP_SETFIELD) { // R[A][K[B]:string] := RK(C)
                const TValue* slot;
                TValue* rb = KB(i);
                TValue* rc = RKC(i);
                TString* key = tsvalue(rb); /* key must be a string */
                if (luaV_fastget(L, s2v(ra), key, slot, luaH_getshortstr)) {
                    luaV_finishfastset(L, s2v(ra), slot, rc);
                } else
                    Protect(luaV_finishset(L, s2v(ra), rb, rc, slot));
                vmbreak;
            }
            vmcase(OP_NEWTABLE) { // R[A] := {}; pc++
                // hash 表的大小
                int b = GETARG_B(i); /* log2(hash size) + 1 */
                // 数组部分的大小
                int c = GETARG_C(i); /* array size */
                Table* t;
                if (b > 0) //
                    b = 1 << (b - 1); /* size is 2^(b - 1) */
                // 如果当前指令的 k 部分为 0, 那么下一指令为无效的扩展指令
                lua_assert((!TESTARG_k(i)) == (GETARG_Ax(*pc) == 0));
                // 如果当前指令的 k 部分为 1, 那么下一条指令为有效的扩展指令
                if (TESTARG_k(i)) /* non-zero extra argument? */
                    c += GETARG_Ax(*pc) * (MAXARG_C + 1); /* add it to size */
                pc++; /* skip extra argument */
                L->top = ra + 1; /* correct top in case of emergency GC */
                t = luaH_new(L); /* memory allocation */
                sethvalue2s(L, ra, t);
                if (b != 0 || c != 0) luaH_resize(L, t, c, b); /* idem */
                checkGC(L, ra + 1);
                vmbreak;
            }
            vmcase(OP_SELF) { // R[A+1] := R[B]; R[A] := R[B][RK(C):string]
                const TValue* slot;
                TValue* rb = vRB(i);
                TValue* rc = RKC(i);
                TString* key = tsvalue(rc); /* key must be a string */
                setobj2s(L, ra + 1, rb);
                if (luaV_fastget(L, rb, key, slot, luaH_getstr)) {
                    setobj2s(L, ra, slot);
                } else
                    Protect(luaV_finishget(L, rb, rc, ra, slot));
                vmbreak;
            }
            vmcase(OP_ADDI) { // R[A] = R[B] + sC; pc++
                op_arithI(L, l_addi, luai_numadd);
                vmbreak;
            }
            vmcase(OP_ADDK) { // R[A] = R[B] + K[C]:number; pc++
                op_arithK(L, l_addi, luai_numadd);
                vmbreak;
            }
            vmcase(OP_SUBK) { // R[A] = R[B] - K[C]:number; pc++
                op_arithK(L, l_subi, luai_numsub);
                vmbreak;
            }
            vmcase(OP_MULK) { // R[A] = R[B] * K[C]:number; pc++
                op_arithK(L, l_muli, luai_nummul);
                vmbreak;
            }
            vmcase(OP_MODK) { // R[A] = R[B] % K[C]:number; pc++
                op_arithK(L, luaV_mod, luaV_modf);
                vmbreak;
            }
            vmcase(OP_POWK) { // R[A] = R[B] ^ K[C]:number; pc++
                op_arithfK(L, luai_numpow);
                vmbreak;
            }
            vmcase(OP_DIVK) { // R[A] = R[B] / K[C]:number; pc++
                op_arithfK(L, luai_numdiv);
                vmbreak;
            }
            vmcase(OP_IDIVK) { // R[A] = R[B] // K[C]:number; pc++
                op_arithK(L, luaV_idiv, luai_numidiv);
                vmbreak;
            }
            vmcase(OP_BANDK) { // R[A] = R[B] & K[C]:integer; pc++
                op_bitwiseK(L, l_band);
                vmbreak;
            }
            vmcase(OP_BORK) { // R[A] = R[B] | K[C]:integer; pc++
                op_bitwiseK(L, l_bor);
                vmbreak;
            }
            vmcase(OP_BXORK) { // R[A] = R[B] ~ K[C]:integer; pc++
                op_bitwiseK(L, l_bxor);
                vmbreak;
            }
            vmcase(OP_SHRI) { // R[A] = R[B] >> sC; pc++
                TValue* rb = vRB(i);
                int ic = GETARG_sC(i);
                lua_Integer ib;
                if (tointegerns(rb, &ib)) {
                    pc++;
                    setivalue(s2v(ra), luaV_shiftl(ib, -ic));
                }
                vmbreak;
            }
            vmcase(OP_SHLI) { // R[A] = sC << R[B]; pc++
                TValue* rb = vRB(i);
                int ic = GETARG_sC(i);
                lua_Integer ib;
                if (tointegerns(rb, &ib)) {
                    pc++;
                    setivalue(s2v(ra), luaV_shiftl(ic, ib));
                }
                vmbreak;
            }
            vmcase(OP_ADD) { // R[A] = R[B] + R[C]; pc++
                op_arith(L, l_addi, luai_numadd);
                vmbreak;
            }
            vmcase(OP_SUB) { // R[A] = R[B] - R[C]; pc++
                op_arith(L, l_subi, luai_numsub);
                vmbreak;
            }
            vmcase(OP_MUL) { // R[A] = R[B] * R[C]; pc++
                op_arith(L, l_muli, luai_nummul);
                vmbreak;
            }
            vmcase(OP_MOD) { // R[A] = R[B] % R[C]; pc++
                op_arith(L, luaV_mod, luaV_modf);
                vmbreak;
            }
            vmcase(OP_POW) { // R[A] = R[B] ^ R[C]; pc++
                op_arithf(L, luai_numpow);
                vmbreak;
            }
            vmcase(OP_DIV) { /* float division (always with floats) */
                op_arithf(L, luai_numdiv); // R[A] = R[B] / R[C]; pc++
                vmbreak;
            }
            vmcase(OP_IDIV) { /* floor division */
                op_arith(L, luaV_idiv, luai_numidiv); // R[A] = R[B] // R[C]; pc++
                vmbreak;
            }
            vmcase(OP_BAND) { // R[A] = R[B] & R[C]; pc++
                op_bitwise(L, l_band);
                vmbreak;
            }
            vmcase(OP_BOR) { // R[A] = R[B] | R[C]; pc++
                op_bitwise(L, l_bor);
                vmbreak;
            }
            vmcase(OP_BXOR) { // R[A] = R[B] ~ R[C]; pc++
                op_bitwise(L, l_bxor);
                vmbreak;
            }
            vmcase(OP_SHR) { // R[A] = R[B] >> R[C]; pc++
                op_bitwise(L, luaV_shiftr);
                vmbreak;
            }
            vmcase(OP_SHL) { // R[A] = R[B] << R[C]; pc++
                op_bitwise(L, luaV_shiftl);
                vmbreak;
            }
            vmcase(OP_MMBIN) { // call C metamethod over R[A] and R[B] (*)
                // i 指令的上一条
                Instruction pi = *(pc - 2); /* original arith. expression */
                TValue* rb = vRB(i);
                TMS tm = (TMS)GETARG_C(i); // C 为元方法的索引
                StkId result = RA(pi);
                // 上一条指令一定是 OP_ADD 到 OP_SHR 中的一条
                lua_assert(OP_ADD <= GET_OPCODE(pi) && GET_OPCODE(pi) <= OP_SHR);
                Protect(luaT_trybinTM(L, s2v(ra), rb, result, tm));
                vmbreak;
            }
            vmcase(OP_MMBINI) { // call C metamethod over R[A] and sB
                Instruction pi = *(pc - 2); /* original arith. expression */
                int imm = GETARG_sB(i);
                TMS tm = (TMS)GETARG_C(i);
                int flip = GETARG_k(i);
                StkId result = RA(pi);
                Protect(luaT_trybiniTM(L, s2v(ra), imm, flip, result, tm));
                vmbreak;
            }
            vmcase(OP_MMBINK) { // call C metamethod over R[A] and K[B]
                Instruction pi = *(pc - 2); /* original arith. expression */
                TValue* imm = KB(i);
                TMS tm = (TMS)GETARG_C(i);
                int flip = GETARG_k(i);
                StkId result = RA(pi);
                Protect(luaT_trybinassocTM(L, s2v(ra), imm, flip, result, tm));
                vmbreak;
            }
            vmcase(OP_UNM) { // R[A] := -R[B]
                TValue* rb = vRB(i);
                lua_Number nb;
                if (ttisinteger(rb)) {
                    lua_Integer ib = ivalue(rb);
                    setivalue(s2v(ra), intop(-, 0, ib));
                } else if (tonumberns(rb, nb)) {
                    setfltvalue(s2v(ra), luai_numunm(L, nb));
                } else
                    Protect(luaT_trybinTM(L, rb, rb, ra, TM_UNM));
                vmbreak;
            }
            vmcase(OP_BNOT) { // R[A] := ~R[B]
                TValue* rb = vRB(i);
                lua_Integer ib;
                if (tointegerns(rb, &ib)) {
                    setivalue(s2v(ra), intop(^, ~l_castS2U(0), ib));
                } else
                    Protect(luaT_trybinTM(L, rb, rb, ra, TM_BNOT));
                vmbreak;
            }
            vmcase(OP_NOT) { // R[A] := not R[B]
                TValue* rb = vRB(i);
                if (l_isfalse(rb))
                    setbtvalue(s2v(ra));
                else
                    setbfvalue(s2v(ra));
                vmbreak;
            }
            vmcase(OP_LEN) { // R[A] := #R[B] (length operator)
                Protect(luaV_objlen(L, ra, vRB(i)));
                vmbreak;
            }
            vmcase(OP_CONCAT) { // R[A] := R[A].. ... ..R[A + B - 1]
                int n = GETARG_B(i); /* number of elements to concatenate */
                L->top = ra + n; /* mark the end of concat operands */
                ProtectNT(luaV_concat(L, n));
                checkGC(L, L->top); /* 'luaV_concat' ensures correct top */
                vmbreak;
            }
            vmcase(OP_CLOSE) { // A close all upvalues >= R[A]
                Protect(luaF_close(L, ra, LUA_OK, 1));
                vmbreak;
            }
            vmcase(OP_TBC) { // mark variable A "to be closed"
                /* create new to-be-closed upvalue */
                halfProtect(luaF_newtbcupval(L, ra));
                vmbreak;
            }
            vmcase(OP_JMP) { // pc += sJ
                dojump(ci, i, 0);
                vmbreak;
            }
            vmcase(OP_EQ) { // if ((R[A] == R[B]) ~= k) then pc++
                int cond;
                TValue* rb = vRB(i);
                Protect(cond = luaV_equalobj(L, s2v(ra), rb));
                docondjump();
                vmbreak;
            }
            vmcase(OP_LT) { // if ((R[A] < R[B]) ~= k) then pc++
                op_order(L, l_lti, LTnum, lessthanothers);
                vmbreak;
            }
            vmcase(OP_LE) { // if ((R[A] <= R[B]) ~= k) then pc++
                op_order(L, l_lei, LEnum, lessequalothers);
                vmbreak;
            }
            vmcase(OP_EQK) { // if ((R[A] == K[B]) ~= k) then pc++
                TValue* rb = KB(i);
                /* basic types do not use '__eq'; we can use raw equality */
                int cond = luaV_rawequalobj(s2v(ra), rb);
                docondjump();
                vmbreak;
            }
            vmcase(OP_EQI) { // if ((R[A] == sB) ~= k) then pc++
                int cond;
                int im = GETARG_sB(i);
                if (ttisinteger(s2v(ra)))
                    cond = (ivalue(s2v(ra)) == im);
                else if (ttisfloat(s2v(ra)))
                    cond = luai_numeq(fltvalue(s2v(ra)), cast_num(im));
                else
                    cond = 0; /* other types cannot be equal to a number */
                docondjump();
                vmbreak;
            }
            vmcase(OP_LTI) { // if ((R[A] < sB) ~= k) then pc++
                op_orderI(L, l_lti, luai_numlt, 0, TM_LT);
                vmbreak;
            }
            vmcase(OP_LEI) { // if ((R[A] <= sB) ~= k) then pc++
                op_orderI(L, l_lei, luai_numle, 0, TM_LE);
                vmbreak;
            }
            vmcase(OP_GTI) {
                op_orderI(L, l_gti, luai_numgt, 1, TM_LT);
                vmbreak;
            }
            vmcase(OP_GEI) { // if ((R[A] >= sB) ~= k) then pc++
                op_orderI(L, l_gei, luai_numge, 1, TM_LE);
                vmbreak;
            }
            vmcase(OP_TEST) {
                int cond = !l_isfalse(s2v(ra));
                docondjump();
                vmbreak;
            }
            vmcase(OP_TESTSET) { // if (not R[B] == k) then pc++ else R[A] := R[B]
                TValue* rb = vRB(i);
                if (l_isfalse(rb) == GETARG_k(i))
                    pc++;
                else {
                    setobj2s(L, ra, rb);
                    donextjump(ci);
                }
                vmbreak;
            }
            vmcase(OP_CALL) {
                CallInfo* newci;
                int b = GETARG_B(i); // 函数签名中参数个数
                int nresults = GETARG_C(i) - 1; // 要被调用函数的返回个数
                if (b != 0) /* fixed number of arguments? */
                    L->top = ra + b; /* top signals number of arguments */
                /* else previous instruction set top */
                // 保存了 OP_CALL 的下一指令索引到 savedpc 中, 如果出现异常可以正常运行
                savepc(L); /* in case of errors */
                // ra 为要调用函数的寄存器
                if ((newci = luaD_precall(L, ra, nresults)) == NULL)
                    // 如果是 c 函数调用, luaD_precall 已经调用完毕
                    updatetrap(ci); /* C call; nothing else to be done */
                else { /* Lua call: run function in this same C frame */
                    // 如果是 lua 调用, 刚在相同的 c 调用帧上进行
                    ci = newci;
                    goto startfunc; // 在 lu a 函数中继续调用 lua 函数
                }
                vmbreak;
            }
            vmcase(OP_TAILCALL) {
                int b = GETARG_B(i); /* number of arguments + 1 (function) */
                int n; /* number of results when calling a C function */
                int nparams1 = GETARG_C(i);
                /* delta is virtual 'func' - real 'func' (vararg functions) */
                int delta = (nparams1) ? ci->u.l.nextraargs + nparams1 : 0;
                if (b != 0)
                    L->top = ra + b;
                else /* previous instruction set top */
                    b = cast_int(L->top - ra);
                savepc(ci); /* several calls here can raise errors */
                if (TESTARG_k(i)) {
                    luaF_closeupval(L, base); /* close upvalues from current call */
                    lua_assert(L->tbclist < base); /* no pending tbc variables */
                    lua_assert(base == ci->func + 1);
                }
                if ((n = luaD_pretailcall(L, ci, ra, b, delta)) < 0) /* Lua function? */
                    goto startfunc; /* execute the callee */
                else { /* C function? */
                    ci->func -= delta; /* restore 'func' (if vararg) */
                    luaD_poscall(L, ci, n); /* finish caller */
                    updatetrap(ci); /* 'luaD_poscall' can change hooks */
                    goto ret; /* caller returns after the tail call */
                }
            }
            vmcase(OP_RETURN) {
                int n = GETARG_B(i) - 1; /* number of results */
                int nparams1 = GETARG_C(i);
                if (n < 0) /* not fixed? */
                    n = cast_int(L->top - ra); /* get what is available */
                savepc(ci);
                if (TESTARG_k(i)) { /* may there be open upvalues? */
                    ci->u2.nres = n; /* save number of returns */
                    if (L->top < ci->top) L->top = ci->top;
                    luaF_close(L, base, CLOSEKTOP, 1);
                    updatetrap(ci);
                    updatestack(ci);
                }
                if (nparams1) /* vararg function? */
                    ci->func -= ci->u.l.nextraargs + nparams1;
                L->top = ra + n; /* set call for 'luaD_poscall' */
                luaD_poscall(L, ci, n);
                updatetrap(ci); /* 'luaD_poscall' can change hooks */
                goto ret;
            }
            vmcase(OP_RETURN0) {
                if (l_unlikely(L->hookmask)) {
                    L->top = ra;
                    savepc(ci);
                    luaD_poscall(L, ci, 0); /* no hurry... */
                    trap = 1;
                } else { /* do the 'poscall' here */
                    int nres;
                    // 要返回了
                    L->ci = ci->previous; /* back to caller */
                    L->top = base - 1; // 返回栈顶, 就是 func 所在的栈
                    // 当前 ci 结束时期望从此 ci 返回参数的个数,
                    // 因为没有返回值,所以只能简单调正 top, 把接收寄存器置成 nil,
                    // 如果 nresults 为 -1, 就什么也不用做
                    for (nres = ci->nresults; l_unlikely(nres > 0); nres--) //
                        setnilvalue(s2v(L->top++)); /* all results are nil */
                }
                goto ret;
            }
            vmcase(OP_RETURN1) {
                if (l_unlikely(L->hookmask)) {
                    L->top = ra + 1;
                    savepc(ci);
                    luaD_poscall(L, ci, 1); /* no hurry... */
                    trap = 1;
                } else { /* do the 'poscall' here */
                    int nres = ci->nresults;
                    L->ci = ci->previous; /* back to caller */
                    if (nres == 0) // 如果调用者不需要返回值, 修正 top 到 func 的位置
                        L->top = base - 1; /* asked for no results */
                    else {
                        setobjs2s(L, base - 1, ra); /* at least this result */
                        L->top = base;
                        for (; l_unlikely(nres > 1); nres--) // 调用者多余的调用值置 nil
                            setnilvalue(s2v(L->top++)); /* complete missing results */
                    }
                }
            // 尾调用与三个返回最后都到这里
            ret: /* return from a Lua function */
                if (ci->callstatus & CIST_FRESH)
                    return; /* end this frame */
                else {
                    ci = ci->previous; // 恢复调用函数的环境, 继续执行
                    goto returning; /* continue running caller in this frame */
                }
            }
            vmcase(OP_FORLOOP) { // update counters; if loop continues then pc-=Bx;
                if (ttisinteger(s2v(ra + 2))) { /* integer loop? */
                    lua_Unsigned count = l_castS2U(ivalue(s2v(ra + 1)));
                    if (count > 0) { /* still more iterations? */
                        lua_Integer step = ivalue(s2v(ra + 2));
                        lua_Integer idx = ivalue(s2v(ra)); /* internal index */
                        chgivalue(s2v(ra + 1), count - 1); /* update counter */
                        idx = intop(+, idx, step); /* add step to index */
                        chgivalue(s2v(ra), idx); /* update internal index */
                        setivalue(s2v(ra + 3), idx); /* and control variable */
                        pc -= GETARG_Bx(i); /* jump back */
                    }
                } else if (floatforloop(ra)) /* float loop */
                    pc -= GETARG_Bx(i); /* jump back */
                updatetrap(ci); /* allows a signal to break the loop */
                vmbreak;
            }
            vmcase(OP_FORPREP) {
                savestate(L, ci); /* in case of errors */
                if (forprep(L, ra)) pc += GETARG_Bx(i) + 1; /* skip the loop */
                vmbreak;
            }
            vmcase(OP_TFORPREP) { // create upvalue for R[A + 3]; pc+=Bx
                /* create to-be-closed upvalue (if needed) */
                halfProtect(luaF_newtbcupval(L, ra + 3));
                pc += GETARG_Bx(i);
                i = *(pc++); /* go to next instruction */
                lua_assert(GET_OPCODE(i) == OP_TFORCALL && ra == RA(i));
                goto l_tforcall;
            }
            vmcase(OP_TFORCALL) {
            l_tforcall:
                /* 'ra' has the iterator function, 'ra + 1' has the state,
                   'ra + 2' has the control variable, and 'ra + 3' has the
                   to-be-closed variable. The call will use the stack after
                   these values (starting at 'ra + 4')
                */
                /* push function, state, and control variable */
                memcpy(ra + 4, ra, 3 * sizeof(*ra));
                L->top = ra + 4 + 3;
                ProtectNT(luaD_call(L, ra + 4, GETARG_C(i))); /* do the call */
                updatestack(ci); /* stack may have changed */
                i = *(pc++); /* go to next instruction */
                lua_assert(GET_OPCODE(i) == OP_TFORLOOP && ra == RA(i));
                goto l_tforloop;
            }
            vmcase(OP_TFORLOOP) {
            l_tforloop:
                if (!ttisnil(s2v(ra + 4))) { /* continue loop? */
                    setobjs2s(L, ra + 2, ra + 4); /* save control variable */
                    pc -= GETARG_Bx(i); /* jump back */
                }
                vmbreak;
            }
            vmcase(OP_SETLIST) { // R[A][C+i] := R[A+i], 1 <= i <= B
                int n = GETARG_B(i);
                unsigned int last = GETARG_C(i);
                Table* h = hvalue(s2v(ra));
                if (n == 0)
                    n = cast_int(L->top - ra) - 1; /* get up to the top */
                else
                    L->top = ci->top; /* correct top in case of emergency GC */
                last += n;
                if (TESTARG_k(i)) {
                    last += GETARG_Ax(*pc) * (MAXARG_C + 1);
                    pc++;
                }
                if (last > luaH_realasize(h)) /* needs more space? */
                    luaH_resizearray(L, h, last); /* preallocate it at once */
                for (; n > 0; n--) {
                    TValue* val = s2v(ra + n);
                    setobj2t(L, &h->array[last - 1], val);
                    last--;
                    luaC_barrierback(L, obj2gco(h), val);
                }
                vmbreak;
            }
            vmcase(OP_CLOSURE) { // R[A] := closure(KPROTO[Bx])
                Proto* p = cl->p->p[GETARG_Bx(i)];
                halfProtect(pushclosure(L, p, cl->upvals, base, ra)); // 在虚拟机运行的过程中被动态构造出的 lua 闭包
                checkGC(L, ra + 1);
                vmbreak;
            }
            vmcase(OP_VARARG) { // R[A], R[A+1], ..., R[A+C-2] = vararg
                int n = GETARG_C(i) - 1; /* required results */
                Protect(luaT_getvarargs(L, ci, ra, n));
                vmbreak;
            }
            vmcase(OP_VARARGPREP) {
                ProtectNT(luaT_adjustvarargs(L, GETARG_A(i), ci, cl->p));
                if (l_unlikely(trap)) { /* previous "Protect" updated trap */
                    luaD_hookcall(L, ci);
                    L->oldpc = 1; /* next opcode will be seen as a "new" line */
                }
                updatebase(ci); /* function has new base after adjustment */
                vmbreak;
            }
            vmcase(OP_EXTRAARG) { // 如果额外参数都被正解处理了, 就不可能进入到这里
                lua_assert(0);
                vmbreak;
            }
        }
    }
}

/* }================================================================== */
