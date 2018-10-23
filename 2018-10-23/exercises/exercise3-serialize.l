SIMPLECHAR  [ -~]

%%

                printf("\"");

\a              printf("\\a");
\b              printf("\\b");
\f              printf("\\f");
\n              printf("\\n");
\r              printf("\\r");
\t              printf("\\t");
\v              printf("\\v");
\\              printf("\\\\");
\"              printf("\\\"");

{SIMPLECHAR}    printf("%c", yytext[0]);

.               printf("\\%03o", yytext[0] & 0xFF);

%%

int yywrap(void)
{
  printf("\"\n"); 
  return 1;
}

int main(void) {
  yylex();
  return 0;
}
