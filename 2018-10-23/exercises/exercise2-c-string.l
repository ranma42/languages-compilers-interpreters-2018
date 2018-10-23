              int extract_bits(int x, int idx) {
                return (x >> (idx * 6)) & 0x3F;
              }

              void print_utf8(int x) {
                if (x < 0x80) {
                  printf("%c", x);
                } else if (x <= 0x800) {
                  printf("%c", 0xC0 | extract_bits(x, 1));
                  printf("%c", 0x80 | extract_bits(x, 0));
                } else if (x <= 0x10000) {
                  printf("%c", 0xE0 | extract_bits(x, 2));
                  printf("%c", 0x80 | extract_bits(x, 1));
                  printf("%c", 0x80 | extract_bits(x, 0));
                } else {
                  printf("%c", 0xF0 | extract_bits(x, 3));
                  printf("%c", 0x80 | extract_bits(x, 2));
                  printf("%c", 0x80 | extract_bits(x, 1));
                  printf("%c", 0x80 | extract_bits(x, 0));
                }
              }

DQUOTE      ["]
SIMPLECHAR  [^"\\]
HEX         [0-9a-fA-F]
OCT         [0-7]

%x escaped
%%

{DQUOTE}                  BEGIN(escaped);

<escaped>{DQUOTE}         BEGIN(INITIAL);
<escaped>{SIMPLECHAR}+    printf("%s", yytext);
<escaped>\\a              printf("\a");
<escaped>\\b              printf("\b");
<escaped>\\f              printf("\f");
<escaped>\\n              printf("\n");
<escaped>\\r              printf("\r");
<escaped>\\t              printf("\t");
<escaped>\\v              printf("\v");
<escaped>\\\\             printf("\\");
<escaped>\\\'             printf("\'");
<escaped>\\\"             printf("\"");
<escaped>\\\?             printf("\?");
<escaped>\\{OCT}{1,3}     printf("%c", (int) strtol(yytext+1, NULL, 8));
<escaped>\\x{HEX}+        printf("%c", (int) strtol(yytext+2, NULL, 16));
<escaped>\\U{HEX}{8}      print_utf8(strtol(yytext+2, NULL, 16));
<escaped>\\u{HEX}{4}      print_utf8(strtol(yytext+2, NULL, 16));

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
