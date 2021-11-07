# SPDX-License-Identifier: GPL-3.0-or-later
# Author: bluewww

CC       = gcc
CFLAGS   = -Og -g -std=gnu11 -Wall -Wextra
CPPFLAGS = -I .
LDLIBS   =

CFLAGS  += `pkg-config --cflags readline`
LDLIBS  += `pkg-config --libs readline`

BISON   = bison
BFLAGS  = -d

all: huelle

huelle: huelle.o

grammar.tab.c grammar.tab.h: grammar.y
	$(BISON) $(BFLAGS) $^

.PHONY: clean
clean:
	$(RM) huelle *.o grammar.tab.c grammar.tab.h tokens.c

# hacks

a.out: grammar.tab.c tokens.c
	$(CC) $^
