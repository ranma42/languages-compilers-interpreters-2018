%{
  #include "expr-grammar.tab.h"
  #include <stdlib.h>
  #include "utils.h"

  void yyerror(char *);
%}

DIGIT    [0-9]
ID       [A-Za-z][A-Za-z0-9]*

%option noyywrap
%%

int                { return INT_TYPE; }
bool               { return BOOL_TYPE; }
true               { return TRUE; }
false              { return FALSE; }
{DIGIT}+           { yylval.value = atoi(yytext); return VAL; }
{ID}               { yylval.id = string_int_get(&global_ids, yytext); return ID; }
[ \t\r]+           /* discard whitespace */
[-*/+><\n\(\)]     { return *yytext; }
\>=                { return GE; }
\<=                { return LE; }
==                 { return EQ; }
!=                 { return NE; }
.                  yyerror("Unexpected character");

%%
