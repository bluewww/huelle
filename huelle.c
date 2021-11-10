/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */

#include <sys/wait.h>
#include <argp.h>
#include <assert.h>
#include <readline/history.h>
#include <readline/readline.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <error.h>

#include "huelle.h"

#include "huelle.tab.h"
#include "huelle.lex.h"

static char *line_read = (char *)NULL;

void *
xmalloc(size_t size)
{
	void *mem = NULL;

	if (size == 0)
		size = 1;
	mem = malloc(size);
	if (!mem) {
		fprintf(stderr, "xmalloc failed\n");
		exit(EXIT_FAILURE);
	}
	return mem;
}

void *
xrealloc(void *ptr, size_t size)
{
	void *mem;
	if (size == 0)
		size = 1;
	if (!ptr)
		mem = malloc(size);
	else
		mem = realloc(ptr, size);
	if (!mem) {
		fprintf(stderr, "xrealloc failed\n");
		exit(EXIT_FAILURE);
	}

	return mem;
}

int
is_number(const char *p)
{
	assert(p);

	do {
		if (!isdigit(*p))
			return 0;
	} while (*++p != '\0');
	return 1;
}

/* Read a string and return a pointer to it. Returns NULL on EOF. */
char *
hul_gets(void)
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

#define HUL_XSTR(s) HUL_STR(s)
#define HUL_STR(s) #s

struct builtin {
	char *name;
	int (*func)(char **);
};

#define HUL_BUILTINS                                                         \
	X(cd)                                                                \
	X(help)                                                              \
	X(exit)

#define X(name) int hul_##name(char **args);
HUL_BUILTINS;
#undef X

#define X(name) (struct builtin) { HUL_STR(name), &hul_##name },
struct builtin builtins[] = { HUL_BUILTINS { 0 } };
#undef X

int
hul_cd(char **args)
{
	if (args[1] == NULL) {
		fprintf(stderr, "huelle: expected argument to `cd'\n");
		return 1;
	} else {
		if (chdir(args[1]) != 0)
			perror("chdir");
	}
	return 0;
}

int
hul_help(__attribute__((unused)) char **args)
{
	printf("bluewww's huelle\n");
	return 0;
}

int
hul_exit(char **args)
{
	if (args[1] != NULL) {
		if (strcmp(args[1], "0") == 0)
			exit(EXIT_SUCCESS);
		else
			exit(EXIT_FAILURE);
	} else
		exit(EXIT_SUCCESS);

	return 0;
}

int
hul_eval_redir(struct hul_redir *redirs)
{
	int f = 0;
	for (struct hul_redir** r = &redirs; *r; r = &((*r)->next)) {
		switch ((*r)->type) {
		case NFROM:
			f = open((*r)->file, O_RDONLY);
			if (f == -1) {
				perror("open");
				return 1;
			}
			if (dup2(f, (*r)->fd_n) == -1) {
				perror("dup2");
				return 1;
			}
			break;
		case NFROMFD:
			/* TODO */
			break;
		case NTO:
			f = open((*r)->file, O_WRONLY | O_CREAT | O_TRUNC, 0666);
			if (f == -1) {
				perror("open");
				return 1;
			}
			if (dup2(f, (*r)->fd_n) == -1) {
				perror("dup2");
				return 1;
			}
			break;
		case NTOFD:
			/* TODO */
			break;
		case NAPPEND:
			f = open((*r)->file, O_WRONLY | O_CREAT | O_APPEND, 0666);
			if (f == -1) {
				perror("open");
				return 1;
			}
			if (dup2(f, (*r)->fd_n) == -1) {
				perror("dup2");
				return 1;
			}
			break;
		case NFROMTO:
			/* TODO */
			break;
		case NCLOBBER:
			/* TODO */
			break;
		}
	}
	return 0;
}

int
hul_eval_pipe(struct hul_pipe *pipes)
{
	pid_t pid, wpid;
	int pipefd[2];
	int status;
	int fdin = 0;

	for (struct hul_pipe** p = &pipes; *p; p = &((*p)->right)) {
		struct hul_simple_cmd *cmd = (*p)->left;

		/* run builtins */
		bool is_builtin = false;
		for (struct builtin *bin = builtins; bin->name; bin++)
			if (strcmp(cmd->args[0], bin->name) == 0) {
				is_builtin = true;
				(*bin->func)(cmd->args); /* TODO: handle shell return code */
				break;
			}
		if (is_builtin)
			continue;

		if (pipe(pipefd)) {
			perror("pipe2");
			return EXIT_FAILURE;
		}

		pid = fork();
		if (pid == 0) {
			/* apply pipe input and output chaining */
			if (dup2(fdin, 0) == -1) {
				perror("dup2");
				return EXIT_FAILURE;
			}
			if ((*p)->right)
				if (dup2(pipefd[1], 1) == -1) {
					perror("dup2");
					return EXIT_FAILURE;
				}
			if (close(pipefd[0]) == -1) {
				perror("close");
				return EXIT_FAILURE;
			}
			/* apply user redirections */
			hul_eval_redir(cmd->prefix);
			hul_eval_redir(cmd->suffix);

			/* finally exec */
			if (execvp(cmd->args[0], cmd->args) == -1) {
				perror("execvp");
				return EXIT_FAILURE;
			}
		} else if (pid > 0) {
			do {
				wpid = waitpid(pid, &status, WUNTRACED);
			} while (!WIFEXITED(status) && !WIFSIGNALED(status));
			if (close(pipefd[1]) == -1) {
				perror("close");
				return EXIT_FAILURE;
			}
			fdin = pipefd[0];
		} else { /* pid < 0 */
			perror("fork");
			return EXIT_FAILURE;
		}
	}

	return 0;
}

void
hul_free_cmd(struct hul_simple_cmd *cmd)
{

	for (char **arg = cmd->args; *arg; arg++)
		free(*arg);
	free(cmd->args);

	struct hul_redir *head;
	struct hul_redir *tmp;
	head = cmd->prefix;
	tmp = NULL;
	while (head) {
		tmp = head;
		head = head->next;
		free(tmp->file);
		free(tmp);
	}

	head = cmd->suffix;
	tmp = NULL;
	while (head) {
		tmp = head;
		head = head->next;
		free(tmp->file);
		free(tmp);
	}

	free(cmd);
}

void
hul_free_pipe(struct hul_pipe *pipes)
{
	for (struct hul_pipe **p = &pipes; *p; p = &((*p)->right)) {
		struct hul_simple_cmd *cmd = (*p)->left;
		hul_free_cmd(cmd);
	}
	if (pipes)
		free(pipes);
}

char *hul_line = NULL;
char **args = NULL;

#if !YYDEBUG
static int yydebug;
#endif


const char *huelle_version = "huelle 1.0";
const char *huelle_bugs = "<balasr@iis.ee.ethz.ch>";
static char doc[] = "huelle -- a small shell";

static char args_doc[] = "";

static struct argp_option options[] = {
	{"verbose", 'v', 0, 0, "Produce verbose output", 0},
	{"debug", 'd', 0, 0, "Show debug information", 0},
	{0}
};

struct arguments
{
	int verbose, debug;
};

static error_t
parse_opt(int key, __attribute__((unused)) char *arg, struct argp_state *state)
{
	struct arguments *arguments = state->input;

	switch (key)
	{
	case 'v':
		arguments->verbose = 1;
		break;
	case 'd':
		arguments->debug = 1;
		break;
	case  ARGP_KEY_ARG:
		if (state->arg_num > 0)
			argp_usage(state);
		break;
	case ARGP_KEY_END:
		break;
	default:
		return ARGP_ERR_UNKNOWN;
	}
	return 0;
}

static struct argp argp = {options, parse_opt, args_doc, doc, NULL, NULL, NULL};

int
main(int argc, char **argv)
{
	struct arguments arguments = {0};
	argp_parse(&argp, argc, argv, 0, 0, &arguments);

	yyscan_t scanner;
	yylex_init(&scanner);
	yyset_debug(1, scanner);

	if (arguments.debug)
		yydebug = 1;

	for (;;) {
		/* allocates the read string and frees it once we come back
		 * here */
		if (!(hul_line = hul_gets())) {
			printf("\n");
			goto success; /* eof */
		}
#ifdef HUL_DEBUG
		printf("PARSING:%s\n", hul_line);
#endif
		YY_BUFFER_STATE buffer = yy_scan_string(hul_line, scanner);
		yyparse(scanner);
		yy_delete_buffer(buffer, scanner);
	}

success:
	if (hul_line)
		free(hul_line);
	yylex_destroy(scanner);
	return EXIT_SUCCESS;
}
