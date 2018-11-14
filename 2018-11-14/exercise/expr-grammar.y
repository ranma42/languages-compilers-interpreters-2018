%{
  #include <stdio.h>
  int yylex(void);
  void yyerror(char *);

  int gen_reg() {
    static int next_reg = 0;
    return next_reg++;
  }
%}

%token VAL

%left '+' '-'
%left '*' '/'

%%
program:
    program expr '\n'    { printf("ret r%d\n", $2); }
    |
    ;

expr: VAL             { $$ = gen_reg(); printf("mov r%d, %d\n", $$, $1); }
      | expr '+' expr { $$ = gen_reg(); printf("add r%d, r%d, r%d\n", $$, $1, $3); }
      | expr '-' expr { $$ = gen_reg(); printf("sub r%d, r%d, r%d\n", $$, $1, $3); }
      | expr '*' expr { $$ = gen_reg(); printf("mul r%d, r%d, r%d\n", $$, $1, $3); }
      | expr '/' expr { $$ = gen_reg(); printf("div r%d, r%d, r%d\n", $$, $1, $3); }
      | '(' expr ')'  { $$ = $2; }
      ;

%%

void yyerror(char* s){
    fprintf(stderr, "%s\n", s);
}

int main(void){
    yyparse();
    return 0;
}
