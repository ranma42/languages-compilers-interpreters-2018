%{
  #include "expr-grammar.tab.h"
  #include <stdlib.h>
  void yyerror(char *);
%}

DIGIT    [0-9]

%option noyywrap
%%

{DIGIT}+           { yylval = atoi(yytext); return VAL; }
[ \t\r]+           /* discard whitespace */
[-*/+\n\(\)]       return *yytext;
.                  yyerror("Unexpected character");

%%
