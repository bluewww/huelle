/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */
%{
#include <stdio.h>
#include <readline/history.h>
#include <readline/readline.h>
#include "example.tab.h"
#include "example.lex.h"

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
yyerror (YYLTYPE* yyllocp, __attribute__((unused)) yyscan_t unused,
	 const char* msg)
{
	fprintf (stderr, "%s\n", msg);
}

static char *line_read = NULL;

/* Read a string and return a pointer to it. Returns NULL on EOF. */
char *
gra_gets(void)
{
	if (line_read) {
		free(line_read);
		line_read = (char *)NULL;
	}

	line_read = readline("$ ");

	if (line_read && *line_read)
		add_history(line_read);

	return (line_read);
}

char *gra_line = NULL;

int
main(void)
{
	yyscan_t scanner;
	yylex_init(&scanner);
	yyset_debug(1, scanner);

	for (;;) {
		while(!(gra_line = gra_gets())) {
			printf("\n");
			return EXIT_SUCCESS;
		}
		YY_BUFFER_STATE buffer = yy_scan_string(gra_line, scanner);
		yyparse(scanner);
		yy_delete_buffer(buffer, scanner);
	}

	yylex_destroy(scanner);
	return 0;
}
