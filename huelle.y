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
%}

%code requires {
	/* avoid circular dependency */
	typedef void* yyscan_t;
}

%define api.pure full
%define parse.error detailed
%define parse.assert
%define parse.trace
%locations

%param { yyscan_t scanner }

%union {
	int num;
	char* str;
	struct hul_pipe* pipe;
	struct hul_simple_cmd* simple;
	struct hul_redir* redir;
}

%token PIPE
%token NEWL
%token	<str>		WORD
%token	<num>		IO_NUMBER


%token  GREATER LESS

%token  DLESS  DGREAT  LESSAND  GREATAND  LESSGREAT  DLESSDASH
/*      '<<'   '>>'    '<&'     '>&'      '<>'       '<<-'   */

%token  CLOBBER
/*      '>|'   */

/* %type <str> command */
%type	<pipe>		pipe_sequence;
%type	<simple>	command;
%type	<simple>	simple_command;
%type	<redir>		cmd_prefix;
%type	<simple>	cmd_suffix;
%type	<str>		cmd_name;
%type	<str>		cmd_word;
%type	<redir>		io_redirect;
%type	<redir>		io_file;
%type	<redir>		filename;

%%
program:	pipe_sequence
		{
			if (!($1)) {
				fprintf(stderr, "error: command/pipe is null/unimplemented\n");
				return 0;
			}

			hul_eval_pipe($1);
#ifdef HUL_DEBUG
			for (struct hul_pipe **p = &$1; *p; p = &((*p)->right)) {
				struct hul_simple_cmd *cmd = (*p)->left;
				printf("COMMAND ready:\n");
				for (size_t i = 0; i < cmd->pos; i++)
					printf("\targ[%lu]=%s\n", i, cmd->args[i]);

				struct hul_redir **redir = &cmd->prefix;
				for (struct hul_redir **r = redir; *r; r = &((*r)->next))
					printf("\tprefix redir %d->%s\n", (*r)->fd_n, (*r)->file);

				struct hul_redir **redir2 = &cmd->suffix;
				for (struct hul_redir **r = redir2; *r; r = &((*r)->next))
					printf("\tsuffix redir %d->%s\n", (*r)->fd_n, (*r)->file);

				printf("|\n");
			}
#endif
			hul_free_pipe($1);
		}
		;
pipe_sequence:		command
		{
			struct hul_pipe *pipe = xmalloc(sizeof(*pipe));
			*pipe = (struct hul_pipe){0};
			pipe->left = $1;
			$$ = pipe;
		}
	|	pipe_sequence PIPE linebreak command
		{
			struct hul_pipe *pipe = xmalloc(sizeof(*pipe));
			*pipe = (struct hul_pipe){0};
			pipe->left = $4;
			$1->right = pipe;
			$$ = $1;
		}
		;
command:	simple_command { $$ = $1; }
		;
simple_command: cmd_prefix cmd_word cmd_suffix
		{
			$3->args[0] = $2;
			$3->args[$3->pos] = NULL;
			$3->prefix = $1;
			$$ = $3;
		}
	|	cmd_prefix cmd_word
		{
			struct hul_simple_cmd *cmd = xmalloc(sizeof(*cmd));
			*cmd = (struct hul_simple_cmd){0};
			cmd->args = xmalloc(sizeof(*cmd->args) * 2);
			cmd->size = sizeof(*cmd->args) * 2;
			cmd->pos = 1;
			cmd->args[0] = $2;
			cmd->args[1] = NULL;
			cmd->prefix = $1;
			$$ = cmd;
		}
	|	cmd_prefix
		{
			struct hul_simple_cmd *cmd = xmalloc(sizeof(*cmd));
			*cmd = (struct hul_simple_cmd){0};
			cmd->prefix = $1;
			$$ = cmd;
		}
	|	cmd_name cmd_suffix
		{
			$2->args[0] = $1;
			$2->args[$2->pos] = NULL;
			$$ = $2;
		}
	|	cmd_name
		{
			struct hul_simple_cmd *cmd = xmalloc(sizeof(*cmd));
			*cmd = (struct hul_simple_cmd){0};
			cmd->args = xmalloc(sizeof(*cmd->args) * 2);
			cmd->size = sizeof(*cmd->args) * 2;
			cmd->pos = 1;
			cmd->args[0] = $1;
			cmd->args[1] = NULL;
			$$ = cmd;
		}
		;
cmd_name:	WORD { $$ = yylval.str; }
		;
cmd_word:	WORD { $$ = yylval.str; }
		;
cmd_prefix:	io_redirect { $$ = $1; }
	|	cmd_prefix io_redirect
		{
			$1->next = $2;
			$$ = $1;
		}
		;
cmd_suffix:	io_redirect
		{
			struct hul_simple_cmd *cmd = xmalloc(sizeof(*cmd));
			*cmd = (struct hul_simple_cmd){0};
			cmd->args = xmalloc(sizeof(*cmd->args) * BUFSIZE);
			cmd->size = sizeof(*cmd->args) * BUFSIZE;
			cmd->pos = 1; /* args[0] is cmd name, reserved */
			cmd->suffix = $1;
			$$ = cmd;
		}
	|	cmd_suffix io_redirect
		{
			if ($1->suffix) {
				struct hul_redir *prev = $1->suffix;
				$1->suffix = $2;
				$1->suffix->next = prev;
			} else {
				$1->suffix = $2;
			}
			$$ = $1;
		}
	|	WORD
		{
			struct hul_simple_cmd *cmd = xmalloc(sizeof(*cmd));
			*cmd = (struct hul_simple_cmd){0};
			cmd->args = xmalloc(sizeof(*cmd->args) * BUFSIZE);
			cmd->size = sizeof(*cmd->args) * BUFSIZE;
			cmd->pos = 2; /* args[0] is cmd name, reserved */
			cmd->args[1] = yylval.str;
			$$ = cmd;
		}
	|	cmd_suffix WORD
		{
			if ($1->pos * sizeof(*$1->args)>= $1->size - sizeof(*$1->args)) {
				$1->size += BUFSIZE;
				$1->args = xrealloc($1->args, $1->size);
			}
			$1->args[$1->pos++] = yylval.str;
			$$ = $1;
		}
		;
io_redirect:	io_file { $1->fd_n = 1; $$ = $1; } /* standard output */
	|	IO_NUMBER io_file { $2->fd_n = $1; $$ = $2; }
	|	io_here
	|	IO_NUMBER io_here
		;

io_file:	LESS filename
		{
			$2->type = NFROM;
			$$ = $2;
		}
	|	LESSAND filename
		{
			$2->type = NFROMFD;
			$$ = $2;
		}
	|	GREATER filename
		{
			$2->type = NTO;
			$$ = $2;
		}
	|	GREATAND filename
		{
			$2->type = NTOFD;
			$$ = $2;
		}
	|	DGREAT filename
		{
			$2->type = NAPPEND;
			$$ = $2;
		}
	|	LESSGREAT filename
		{
			$2->type = NFROMTO;
			$$ = $2;
		}
	|	CLOBBER filename
		{
			$2->type = NCLOBBER;
			$$ = $2;
		}
		;
filename:	WORD
		{
			struct hul_redir* redir = xmalloc(sizeof(*redir));
			*redir = (struct hul_redir){0};
			redir->file = yylval.str;
			redir->fd_n = 0;
			$$ = redir;
		}
	;
io_here:	DLESS here_end
	|	DLESSDASH here_end
	;
here_end:	WORD
	;
newline_list:	NEWL
	|	newline_list NEWL
	;
linebreak:	newline_list
	|	/* empty */
	;
%%

void
yyerror (__attribute__((unused)) YYLTYPE* yyllocp,
	 __attribute__((unused)) yyscan_t unused,
	 const char* msg)
{
	fprintf(stderr, "%s\n", msg);
}
