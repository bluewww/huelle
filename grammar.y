/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */
%{
#include <stdio.h>
#include "grammar.tab.h"
#include "tokens.h"

/* Pass the argument to yyparse through to yylex. */
extern int yylex (YYSTYPE * yylval_param, YYLTYPE * yylloc_param , yyscan_t yyscanner);
extern void yyerror (YYLTYPE* yyllocp, yyscan_t unused, const char* msg);

%}

%code requires {
	typedef void* yyscan_t;
}

%define api.pure full
%define parse.error detailed
%define parse.trace
%locations

%param { yyscan_t scanner }

%token INT
%left '+'
%left '*'
%%
prog: expr          { printf("-> %d\n", $1); } ;
expr: INT
    | '(' expr ')'  { $$ = $2; }
    | expr '+' expr { $$ = $1 + $3; }
    | expr '*' expr { $$ = $1 * $3; } ;
%%

void
yyerror (YYLTYPE* yyllocp, yyscan_t unused, const char* msg)
{
	fprintf (stderr, "%s\n", msg);
}

int
main(void)
{
	yyscan_t scanner;
	yylex_init(&scanner);
	yyparse(scanner);
	yylex_destroy(scanner);
	return 0;
}
