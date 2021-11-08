/* SPDX-License-Identifier: GPL-3.0-or-later
 * Author: bluewww */

#ifndef __HUELLE_H__
#define __HUELLE_H__

void *xmalloc(size_t size);
void *xrealloc(void *ptr, size_t size);
int hul_run(char **args);

#endif /* __HUELLE_H__ */
