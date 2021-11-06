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
hul_gets()
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

char *hul_line = NULL;
char **hul_toks = NULL;
char **args = NULL;

int
main(void)
{
	for (;;) {
		/* allocates the read string and frees it once we come back
		 * here */
		if (!(hul_line = hul_gets()))
			return EXIT_SUCCESS; /* eof */
		if (hul_line) {
			args = hul_toks = hul_split_line(hul_line);
#ifdef HUL_DEBUG
			for (char **toks = hul_toks; *toks; toks++)
				printf("tok=%s\n", *toks);
#endif
		}
		if (!args[0])
			continue;
		hul_fork_exec(args);
	}
	return EXIT_SUCCESS;
}
