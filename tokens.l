/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */

%{
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "grammar.tab.h"
extern int yylex();
%}

DIGIT [0-9]
OPERATION [+*\(\)]
WORD [a-zA-Z0-9]+

%option noyywrap

%%
[ \t\n];

{DIGIT}+ {
	yylval = atoi(yytext);
	fprintf(stderr, "int:%d\n", yylval);
	return INT;
}

{OPERATION} {
	assert(yyleng == 1);
	yylval = yytext[0];
	fprintf(stderr, "char:%c\n", yylval);
	return yytext[0];
}

%%
