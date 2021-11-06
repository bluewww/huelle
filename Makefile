# SPDX-License-Identifier: GPL-3.0-or-later
# Author: bluewww

CC       = gcc
CFLAGS   = -Og -g -Wall -Wextra
CPPFLAGS = -I .
LDLIBS   =

CFLAGS  += `pkg-config --cflags readline`
LDLIBS  += `pkg-config --libs readline`

all: huelle

huelle: huelle.o

.PHONY: clean
clean:
	$(RM) huelle huelle.o
