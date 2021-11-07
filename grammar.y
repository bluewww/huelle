/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */
%{
#include <stdio.h>
int yylex(void);
%}

%define parse.error detailed
%define parse.trace

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
yyerror (char const *s)
{
	fprintf (stderr, "%s\n", s);
}

int
main(void)
{
	return yyparse();
}
