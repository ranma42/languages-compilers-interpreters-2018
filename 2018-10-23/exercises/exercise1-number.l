SIGN     [+-]
FRAC     [.][[:digit:]]+
NUM      [[:digit:]]+[.]?[[:digit:]]*
EXP      [eE][+-]?[[:digit:]]+

%%

{SIGN}?({NUM}|{FRAC}){EXP}?    printf("%s: %g\n", yytext, atof(yytext));

[[:space:]]                    /* ignore whitespace */
.                              fprintf(stderr, "Unexpected character: '%c'\n", yytext[0]);

%%

int yywrap(void)
{
  return 1;
}

int main(void) {
  yylex();
  return 0;
}
