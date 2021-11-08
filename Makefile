# SPDX-License-Identifier: GPL-3.0-or-later
# Author: bluewww

CC       = gcc
CFLAGS   = -Og -g -std=gnu11 -Wall -Wextra
CPPFLAGS = -I .
LDLIBS   =

CFLAGS  += `pkg-config --cflags readline`
LDLIBS  += `pkg-config --libs readline`

BISON   = bison
YFLAGS  =

FLEX    = flex
LFLAGS  =

CTAGS   = ctags

all: huelle

huelle: huelle.o

grammar.tab.c grammar.tab.h: grammar.y
	$(BISON) -d $(YFLAGS) $<


%.c %.h: %.l
	$(FLEX) --header-file=$(@:.c=.h) $(LFLAGS) -o $(@:.h=.c) $<

.PHONY: clean
clean:
	$(RM) huelle *.o grammar.tab.c grammar.tab.h tokens.c tokens.h a.out

.PHONY: TAGS
TAGS:
	$(CTAGS) -R -e .

# hacks
a.out: grammar.tab.c tokens.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAG) $(LDLIBS) $^
