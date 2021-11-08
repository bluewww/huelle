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

example.tab.c example.tab.h: example.y
	$(BISON) -d $(YFLAGS) $<


%.lex.c %.lex.h: %.l
	$(FLEX) --header-file=$(@:.c=.h) $(LFLAGS) -o $(@:.h=.c) $<

.PHONY: clean
clean:
	$(RM) huelle *.o example.tab.c example.tab.h example.lex.c example.lex.h a.out

.PHONY: TAGS
TAGS:
	$(CTAGS) -R -e .

# hacks
a.out: example.tab.c example.lex.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAG) $(LDLIBS) $^
