/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */
%{
#include <stdio.h>
#include <readline/history.h>
#include <readline/readline.h>
#include "huelle.h"
#include "huelle.tab.h"
#include "huelle.lex.h"

/* Pass the argument to yyparse through to yylex. */
extern int yylex (YYSTYPE * yylval_param, YYLTYPE * yylloc_param , yyscan_t yyscanner);
extern void yyerror (YYLTYPE* yyllocp, yyscan_t unused, const char* msg);

#define BUFSIZE 128

struct hul_cmd {
	char *name;
	int pos;
	char **args;
};

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
	struct hul_cmd *cmd;
}

%token NEWL
%token GREATER
%token WORD

/* %type <str> command */
%type	<cmd>		command;
%type	<cmd>		simple_command;
%type	<cmd>		cmd_suffix;
%type	<str>		cmd_name;

%%
program: command { };

command:	simple_command
		{
			hul_run($1->args);
			for (char **arg = $1->args; *arg; arg++)
				free(*arg);
			free($1->args);
			free($1);
		}
		;
simple_command: cmd_prefix cmd_word cmd_suffix
	|	cmd_prefix cmd_word
	|	cmd_prefix
	|	cmd_name cmd_suffix
		{
			$2->args[0] = $1;
			$2->args[$2->pos] = NULL;
			$2->name = $1;
			printf("COMMAND ready:\n");
			for (int i = 0; i < $2->pos; i++)
				printf("arg%d=%s\n", i, $2->args[i]);
			$$ = $2;
		}
	|	cmd_name
		{
			struct hul_cmd *cmd = xmalloc(sizeof(*cmd));
			cmd->args = xmalloc(sizeof(char*) * 2);
			cmd->pos = 1;
			cmd->args[0] = $1;
			cmd->args[1] = NULL;
			$$ = cmd;
		}
		;
cmd_name:	WORD { printf("cmd_name=%s\n", yylval.str); $$ = yylval.str; }
		;
cmd_word:	WORD { printf("cmd_word=%s\n", yylval.str); }
		;
cmd_prefix:	io_redirect
	|	cmd_prefix io_redirect
		;
cmd_suffix:	io_redirect
	|	cmd_suffix io_redirect
	|	WORD
		{
			struct hul_cmd *cmd = xmalloc(sizeof(*cmd));
			cmd->args = xmalloc(sizeof(char*) * BUFSIZE);
			cmd->pos = 2;
			cmd->args[1] = yylval.str;
			printf("cmd_suffix=%s\n", yylval.str);
			$$ = cmd;
		}
	|	cmd_suffix WORD
		{
			if ($1->pos >= BUFSIZE-1)
				abort();
			$1->args[$1->pos++] = yylval.str; /* TODO: range check for overflow */
			printf("cmd_suffix=%s\n", yylval.str);
			$$ = $1;
		}
		;
io_redirect:	GREATER { puts("io_redirect\n"); }
	;
%%

void
yyerror (__attribute__((unused)) YYLTYPE* yyllocp,
	 __attribute__((unused)) yyscan_t unused,
	 const char* msg)
{
	fprintf(stderr, "%s\n", msg);
}


/* WORD { $$ = yylval.str; } */
