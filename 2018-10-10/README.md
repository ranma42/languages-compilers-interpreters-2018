# Introduction to FLEX

 - `example1-count.l` is a simple scanner which counts the characters and lines of the input stream

 - `example2-csv-naive.l` splits the input stream in records (at newlines) and fields (at commas)

 - `example3-csv-idx.l` extends `example2` by keeping record and field counters

 - `example4-csv-full.l` extends `example3` with support for quoted fields (based on [RFC4180](https://tools.ietf.org/html/rfc4180))

 - `example5-lang-mini.l` shows a simple parser that can distinguish between integer literals, identifiers, keywords, and operators

Assuming that `flex` is available in the environment, each of these files can be transformed into the C source code for a complete program and then compiled by running:

```sh
flex exampleN-description.l # generate lex.yy.c
cc lex.yy.c # compile it to a.out
```

The `a.out` program accepts it input from the standard input stream, therefore it is possible to run it on an input file using input redirection. For example, to compile the first example and run it on this `README.md` file you could run

```sh
flex example1-count.l
cc lex.yy.c
./a.out < README.md
```

from the folder containing this lesson.