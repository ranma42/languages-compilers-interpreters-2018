%{
  #include "expr-grammar.tab.h"
  #include <stdlib.h>
  void yyerror(char *);
%}

DIGIT    [0-9]
ID       [A-Za-z][A-Za-z0-9]*

%option noyywrap
%%

{DIGIT}+           { yylval.value = atoi(yytext); return VAL; }
{ID}               { yylval.id = strdup(yytext); return ID; }
[ \t\r]+           /* discard whitespace */
[-*/+\n\(\)]       return *yytext;
.                  yyerror("Unexpected character");

%%
