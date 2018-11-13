%{
#include "lang.h"
%}

DIGIT    [0-9]
ID       [A-Za-z][A-Za-z0-9]*

%%

{DIGIT}+           return INTEGER;
if|then|else|while return KEYWORD;
{ID}               return IDENTIFIER;
[+-*/]             return OPERATOR;
[ \t\r\n]+         /* discard whitespace */
.                  return BAD_TOKEN;

%%
