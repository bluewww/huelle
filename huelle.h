/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */

#ifndef __HUELLE_H__
#define __HUELLE_H__

#define HUL_OK 0
#define HUL_FAIL 1
#define HUL_FATAL 2

enum hul_redir_type {
	NTO,
	NTO2,
	NCLOBBER,
	NFROM,
	NFROMTO,
	NAPPEND,
	NTOFD,
	NFROMFD,
	NHERE,
	NEXHERE,
	NNOT
};

struct hul_redir {
	enum hul_redir_type type;
	int fd_n;
	char *file;
	struct hul_redir *next;
};

struct hul_simple_cmd {
	size_t pos;
	size_t size;
	char **args;
	struct hul_redir *prefix;
	struct hul_redir *suffix;
};

struct hul_pipe {
	struct hul_simple_cmd *left;
	struct hul_pipe *right;
};

void *xmalloc(size_t size);
void *xrealloc(void *ptr, size_t size);
int hul_run(char **args);
int hul_eval_pipe(struct hul_pipe *pipes);
void hul_free_pipe(struct hul_pipe *pipes);

#endif /* __HUELLE_H__ */
