/*
** $Id: llex.h $
** Lexical Analyzer
** See Copyright Notice in lua.h
*/

#ifndef llex_h
#define llex_h

#include <limits.h>

#include "lobject.h"
#include "lzio.h"

/*
** Single-char tokens (terminal symbols) are represented by their own
** numeric code. Other tokens start at the following value.
*/
#define FIRST_RESERVED (UCHAR_MAX + 1)

#if !defined(LUA_ENV)
#define LUA_ENV "_ENV"
#endif

/// @brief WARNING: if you change the order of this enumeration, grep "ORDER RESERVED"
enum RESERVED {
    /* terminal symbols denoted by reserved words */
    TK_AND = FIRST_RESERVED,
    TK_BREAK,
    TK_DO,
    TK_ELSE,
    TK_ELSEIF,
    TK_END,
    TK_FALSE,
    TK_FOR,
    TK_FUNCTION,
    TK_GOTO,
    TK_IF,
    TK_IN,
    TK_LOCAL,
    TK_NIL,
    TK_NOT,
    TK_OR,
    TK_REPEAT,
    TK_RETURN,
    TK_THEN,
    TK_TRUE,
    TK_UNTIL,
    TK_WHILE,
    /* other terminal symbols */
    TK_IDIV,
    TK_CONCAT,
    TK_DOTS,
    TK_EQ,
    TK_GE,
    TK_LE,
    TK_NE,
    TK_SHL,
    TK_SHR,
    TK_DBCOLON,
    TK_EOS,
    TK_FLT,
    TK_INT,
    TK_NAME,
    TK_STRING
};

/* number of reserved words */
#define NUM_RESERVED (cast_int(TK_WHILE - FIRST_RESERVED + 1))

typedef union {
    lua_Number r;
    lua_Integer i;
    TString *ts;
} SemInfo; /* semantics information */

typedef struct Token {
    int token;
    SemInfo seminfo;
} Token;

/// @brief state of the lexer plus state of the parser when shared by all functions
typedef struct LexState {
    int current;          /* 当前字符（以字符整数的形式存储） current character (charint) */
    int linenumber;       /* 输入行数计数器 input line counter */
    int lastline;         /* 上一个标记的行数 line of last token 'consumed' */
    Token t;              /* 当前标记 current token */
    Token lookahead;      /* 向前看的标记 look ahead token */
    struct FuncState *fs; /* 当前函数（解析器） current function (parser) */
    struct lua_State *L;  // Lua 状态机
    ZIO *z;               /* 输入流 input stream */
    Mbuffer *buff;        /* 用于标记的缓冲区 buffer for tokens */
    Table *h;             /* 用于避免收集/重用字符串 to avoid collection/reuse strings */
    struct Dyndata *dyd;  /* 解析器使用的动态结构 dynamic structures used by the parser */
    TString *source;      /* 当前源名称 current source name */
    TString *envn;        /* 环境变量名称 environment variable name */
} LexState;

LUAI_FUNC void luaX_init(lua_State *L);
LUAI_FUNC void luaX_setinput(lua_State *L, LexState *ls, ZIO *z, TString *source, int firstchar);
LUAI_FUNC TString *luaX_newstring(LexState *ls, const char *str, size_t l);
LUAI_FUNC void luaX_next(LexState *ls);
LUAI_FUNC int luaX_lookahead(LexState *ls);
LUAI_FUNC l_noret luaX_syntaxerror(LexState *ls, const char *s);
LUAI_FUNC const char *luaX_token2str(LexState *ls, int token);

#endif
