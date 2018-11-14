%{
  #include <stdio.h>
  int yylex(void);
  void yyerror(char *);

  struct expr;
  struct expr* literal(int v);
  struct expr* variable(char *id);
  struct expr* binop(struct expr *lhs, char op, struct expr *rhs);
  void print_expr(struct expr *expr);
  void emit_stack_machine(struct expr *expr);
  int emit_reg_machine(struct expr *expr);
  void free_expr(struct expr *expr);
%}

%union {
  int value;
  char *id;
  struct expr *expr;
}

%token <id> ID
%token <value> VAL
%type  <expr>  expr

%left '+' '-'
%left '*' '/'

%%
program:
    program expr '\n' {
        print_expr($2); printf("\n\n");
        emit_stack_machine($2); printf("\n");
        printf("ret r%d\n", emit_reg_machine($2));
        free_expr($2);
      }
    |
    ;

expr: VAL             { $$ = literal($1); }
      | ID            { $$ = variable($1); }
      | expr '+' expr { $$ = binop($1, '+', $3); }
      | expr '-' expr { $$ = binop($1, '-', $3); }
      | expr '*' expr { $$ = binop($1, '*', $3); }
      | expr '/' expr { $$ = binop($1, '/', $3); }
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
