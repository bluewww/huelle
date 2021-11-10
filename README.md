# HULLE
A simple unix shell implementing some posix features.

Uses a re-entrant bison generated parser and flex generated lexer.

## Compile
Requires `readline`, `bison` (reasonably new) and `flex` (reasonable new).

To do a regular build just call
```bash
make all
```

for a debug build do

```bash
make all DEBUG=y
```

but you will need asan support in your compiler.

## Usage
```bash
./huelle -?
Usage: huelle [OPTION...]
huelle -- a small shell

  -d, --debug                Show debug information
  -v, --verbose              Produce verbose output
  -?, --help                 Give this help list
      --usage                Give a short usage message
```

## Examples
Redirect `ls` output into `out` file:
```sh
$ 1>out ls
$ cat out
```

Filter `ls` output with grep:

```sh
$ ls | grep y
example.y
huelle.y
```

Change directory (builtin):
```sh
cd ..
pwd
```
