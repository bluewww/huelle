# SPDX-License-Identifier: GPL-3.0-or-later
# Author: bluewww

CC       = gcc
ifeq ($(DEBUG),y)
CFLAGS   = -Og -g
CPPFLAGS = -I .
else
CFLAGS   = -O2 -g
CPPFLAGS = -I . -DNDEBUG
endif


LDLIBS   =
LDFLAGS  =

CFLAGS  += -std=gnu11 -Wall -Wextra

# doesn't work well on centos machines so we manually expand
# CFLAGS  += `pkg-config --cflags readline`
# LDLIBS  += `pkg-config --libs readline`
CFLAGS  += -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=600 -I/usr/include/ncurses
LDLIBS  += -lreadline

ifeq ($(DEBUG),y)
CFLAGS  += -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer
LDFLAGS += -fsanitize=address -fsanitize=undefined

CFLAGS   += -fstack-protector-all
CPPFLAGS += -D_FORTIFY_SOURCE=2
endif

BISON   = bison
YFLAGS  =

FLEX    = flex
LFLAGS  =

CTAGS   = ctags

all: huelle

huelle: huelle.o huelle.tab.o huelle.lex.o

huelle.o huelle.tab.o huelle.lex.o: huelle.tab.h huelle.lex.h

%.c: %.y
%.c: %.l

%.tab.c %.tab.h: %.y
	$(BISON) -d $(YFLAGS) $<


%.lex.c %.lex.h: %.l
	$(FLEX) --header-file=$(@:.c=.h) $(LFLAGS) -o $(@:.h=.c) $<

.PHONY: clean
clean:
	$(RM) huelle *.o *.tab.c *.tab.h *.lex.c *.lex.h a.out

.PHONY: TAGS
TAGS:
	$(CTAGS) -R -e .

# debugging
a.out: example.tab.c example.lex.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAG) $(LDLIBS) $^
