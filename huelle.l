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
WORD [a-zA-Z0-9]+

%option reentrant
%option noyywrap
%option bison-bridge
%option bison-locations

%%
[ \t];

\n {
	return NEWL;
}

'>' {
	return GREATER;
}


{WORD} {
	yylval->str = strdup(yytext); /* TODO: xstrdup */
	fprintf(stderr, "str:%s\n", yytext);
	return WORD;
}

. {
	return YYUNDEF;
}

%%
