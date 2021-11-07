/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */

#include <sys/wait.h>
#include <assert.h>
#include <readline/history.h>
#include <readline/readline.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

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

#define HUL_TOK_BUFSIZE 64
#define HUL_TOK_DELIM " \t\r\n\a"

char **
hul_split_line(char *line)
{
	assert(line);

	int bufsize = HUL_TOK_BUFSIZE;
	int position = 0;
	char *saveptr = NULL;
	char *tok = NULL;
	char **toks = xmalloc(bufsize * sizeof(char *));

	tok = strtok_r(line, HUL_TOK_DELIM, &saveptr);
	do {
		toks[position++] = tok;
		if (position >= bufsize) {
			bufsize += HUL_TOK_BUFSIZE;
			toks = xrealloc(toks, bufsize * sizeof(char *));
		}
	} while ((tok = strtok_r(NULL, HUL_TOK_DELIM, &saveptr)));

	toks[position] = NULL;

	return toks;
}

int
hul_fork_exec(char **args)
{
	pid_t pid, wpid;
	int status;

	pid = fork();
	if (pid == 0) {
		if (execvp(args[0], args) == -1)
			perror("huelle");
	} else if (pid > 0) {
		do {
			wpid = waitpid(pid, &status, WUNTRACED);
		} while (!WIFEXITED(status) && !WIFSIGNALED(status));
	} else { /* pid < 0 */
		perror("huelle");
	}

	return 0;
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
			perror("huelle");
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
hul_run(char **args)
{
	/* invalid */
	if (!args[0])
		return 0;

	/* builtins */
	for (struct builtin *bin = builtins; bin->name; bin++)
		if (strcmp(args[0], bin->name) == 0)
			return (*bin->func)(args);

	/* binaries */
	return hul_fork_exec(args);
}

char *hul_line = NULL;
char **hul_toks = NULL;
char **args = NULL;

int
main(void)
{
	for (;;) {
		/* allocates the read string and frees it once we come back
		 * here */
		if (!(hul_line = hul_gets())) {
			printf("\n");
			return EXIT_SUCCESS; /* eof */
		}

		if (hul_line) {
			args = hul_toks = hul_split_line(hul_line);
#ifdef HUL_DEBUG
			for (char **toks = hul_toks; *toks; toks++)
				printf("tok=%s\n", *toks);
#endif
		}

		hul_run(args);
	}
	return EXIT_SUCCESS;
}
