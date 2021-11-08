/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */
%{
#include <stdio.h>
#include <readline/history.h>
#include <readline/readline.h>
#include "huelle.tab.h"
#include "huelle.lex.h"

/* Pass the argument to yyparse through to yylex. */
extern int yylex (YYSTYPE * yylval_param, YYLTYPE * yylloc_param , yyscan_t yyscanner);
extern void yyerror (YYLTYPE* yyllocp, yyscan_t unused, const char* msg);
%}

%code requires {
	/* avoid circular dependency */
	typedef void* yyscan_t;
}

%define api.pure full
%define parse.error detailed
%define parse.trace
%locations

%param { yyscan_t scanner }

%union {
	int num;
	char* str;
}

%token NEWL
%token GREATER
%token WORD

%type <str> cmds

%%
prog: cmds { printf("WORD=%s\n", $1); };

cmds: WORD { $$ = yylval.str; }

%%

void
yyerror (__attribute__((unused)) YYLTYPE* yyllocp,
	 __attribute__((unused)) yyscan_t unused,
	 const char* msg)
{
	fprintf (stderr, "%s\n", msg);
}
