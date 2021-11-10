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
%option noyywrap
%option nounput
%option noinput

%%

[ \t] {

}

\n {
	return NEWL;
}

"<&" {
	return LESSAND;
}

">" {
	return GREATER;
}

"<" {
	return LESS;
}

">&" {
	return GREATAND;
}

">>" {
	return DGREAT;
}

"<>" {
	return LESSGREAT;
}

">|" {
	return CLOBBER;
}

"<<" {
	return DLESS;
}

"<<-" {
	return DLESSDASH;
}

"|" {
	return PIPE;
}

{DIGIT}+/(>|<) {
	yylval->num = atoi(yytext); /* TODO: error checking */
#ifdef HUL_DEBUG
	fprintf(stderr, "io:`%d'\n", yylval->num);
#endif
	return IO_NUMBER;
}

{WORD} {
	yylval->str = strdup(yytext); /* TODO: xstrdup */
#ifdef HUL_DEBUG
	fprintf(stderr, "str:`%s'\n", yytext);
#endif
	return WORD;
}

. {
	fprintf(stderr, "undefined token:`%s'\n", yytext);
	return YYUNDEF;
}

%%
