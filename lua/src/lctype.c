/*
** $Id: lctype.c $
** 'ctype' functions for Lua
** See Copyright Notice in lua.h
** C 标准库中 ctype 相关实现
*/

#define lctype_c
#define LUA_CORE

#include "lprefix.h"

#include "lctype.h"

#if !LUA_USE_CTYPE /* { */

#include <limits.h>

#if defined(LUA_UCID) /* accept UniCode IDentifiers? */
/* consider all non-ascii codepoints to be alphabetic */
#define NONA 0x01
#else
#define NONA 0x00 /* default */
#endif

LUAI_DDEF const lu_byte luai_ctype_[UCHAR_MAX + 2] = {
    0x00,  /* EOZ */
    0x00,     0x00,     0x00,     0x00,     0x00,     0x00,     0x00,     0x00,         /* 0. */
    0x00,     0x08,/* */0x08,/* */0x08,/* */0x08,/* */0x08,/* */0x00,     0x00,
    0x00,     0x00,     0x00,     0x00,     0x00,     0x00,     0x00,     0x00,         /* 1. */
    0x00,     0x00,     0x00,     0x00,     0x00,     0x00,     0x00,     0x00,
    0x0c,/* */0x04,/*!*/0x04,/*"*/0x04,/*#*/0x04,/*$*/0x04,/*%*/0x04,/*&*/0x04,/*'*/    /* 2. */
    0x04,/*(*/0x04,/*)*/0x04,/***/0x04,/*+*/0x04,/*,*/0x04,/*-*/0x04,/*.*/0x04,/*/*/
    0x16,/*0*/0x16,/*1*/0x16,/*2*/0x16,/*3*/0x16,/*4*/0x16,/*5*/0x16,/*6*/0x16,/*7*/    /* 3. */
    0x16,/*8*/0x16,/*9*/0x04,/*:*/0x04,/*;*/0x04,/*<*/0x04,/*=*/0x04,/*>*/0x04,/*?*/
    0x04,/*@*/0x15,/*A*/0x15,/*B*/0x15,/*C*/0x15,/*D*/0x15,/*E*/0x15,/*F*/0x05,/*G*/    /* 4. */
    0x05,/*H*/0x05,/*I*/0x05,/*J*/0x05,/*K*/0x05,/*L*/0x05,/*M*/0x05,/*N*/0x05,/*O*/
    0x05,/*P*/0x05,/*Q*/0x05,/*R*/0x05,/*S*/0x05,/*T*/0x05,/*U*/0x05,/*V*/0x05,/*W*/    /* 5. */
    0x05,/*X*/0x05,/*Y*/0x05,/*Z*/0x04,/*[*/0x04,/*\*/0x04,/*]*/0x04,/*^*/0x05,/*_*/
    0x04,/*`*/0x15,/*a*/0x15,/*b*/0x15,/*c*/0x15,/*d*/0x15,/*e*/0x15,/*f*/0x05,/*g*/    /* 6. */
    0x05,/*h*/0x05,/*i*/0x05,/*j*/0x05,/*k*/0x05,/*l*/0x05,/*m*/0x05,/*n*/0x05,/*o*/
    0x05,/*p*/0x05,/*q*/0x05,/*r*/0x05,/*s*/0x05,/*t*/0x05,/*u*/0x05,/*v*/0x05,/*w*/    /* 7. */
    0x05,/*x*/0x05,/*y*/0x05,/*z*/0x04,/*{*/0x04,/*|*/0x04,/*}*/0x04,/*~*/0x00,
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,         /* 8. */
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,         /* 9. */
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,         /* a. */
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,         /* b. */
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,
    0x00,     0x00,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,         /* c. */
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,         /* d. */
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,         /* e. */
    NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,     NONA,
    NONA,     NONA,     NONA,     NONA,     NONA,     0x00,     0x00,     0x00,         /* f. */
    0x00,     0x00,     0x00,     0x00,     0x00,     0x00,     0x00,     0x00
};

#endif /* } */
