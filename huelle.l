/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */

%{
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "huelle.tab.h"
%}

DIGIT [0-9]
OPERATION [+*\(\)]
WORD [a-zA-Z0-9\-\.\/]+

%option reentrant
%option noyywrap
%option bison-bridge
%option bison-locations

%%
[ \t] {

}

\n {
	return NEWL;
}

> {
	fprintf(stderr, "GREATER\n");
	return GREATER;
}


{WORD} {
	yylval->str = strdup(yytext); /* TODO: xstrdup */
	fprintf(stderr, "str:`%s'\n", yytext);
	return WORD;
}

. {
	fprintf(stderr, "undefined token:`%s'\n", yytext);
	return YYUNDEF;
}

%%
