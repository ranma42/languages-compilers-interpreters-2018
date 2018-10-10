DIGIT    [0-9]
ID       [A-Za-z][A-Za-z0-9]*

%%

{DIGIT}+           printf("Literal integer: %s (%d)\n", yytext, atoi(yytext));
if|then|else|while printf("Keyword: %s\n", yytext);
{ID}               printf("Identifier: %s\n", yytext);
"+"|"-"|"*"|"/"    printf("Operator: %s\n", yytext);
[ \t\r\n]+         /* discard whitespace */
.                  printf( "Unrecognized character: %s\n", yytext);

%%

int yywrap(void)
{
  return 1;
}

int main()
{
  yylex();
  return 0;
}
