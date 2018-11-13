#include <stdio.h>
#include <stdlib.h>
#include "lang.h"

extern int yylex(void);
extern char* yytext;

int yywrap(void)
{
  return 1;
}

int main(void)
{
  int token;

  while ((token = yylex())) {
    switch (token) {
    case INTEGER:
      printf("Literal integer: %s (%d)\n", yytext, atoi(yytext));
      break;
    case IDENTIFIER:
      printf("Identifier: %s\n", yytext);
      break;
    case OPERATOR:
      printf("Operator: %s\n", yytext);
      break;
    case KEYWORD:
      printf("Keyword: %s\n", yytext);
      break;
    case BAD_TOKEN:
      printf("Unrecognized character: %s\n", yytext);
      break;
    default:
      printf("Unknown token: %d %s\n", token, yytext);
    }
  }
  return 0;
}
