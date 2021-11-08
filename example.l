/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */

%{
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "example.tab.h"
%}

DIGIT [0-9]
OPERATION [+*\(\)]
WORD [a-zA-Z0-9]+

%option reentrant
%option noyywrap
%option bison-bridge
%option bison-locations

%%
[ \t\n];

{DIGIT}+ {
	*yylval = atoi(yytext);
	fprintf(stderr, "int:%d\n", *yylval);
	return INT;
}

{OPERATION} {
	assert(yyleng == 1);
	*yylval = yytext[0];
	fprintf(stderr, "char:%c\n", *yylval);
	return yytext[0];
}

%%
