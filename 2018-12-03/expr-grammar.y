%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "utils.h"

  int yylex(void);
  void yyerror(char *);

  struct expr;
  struct expr* bool_lit(int v);
  struct expr* literal(int v);
  struct expr* variable(size_t id);
  struct expr* binop(struct expr *lhs, int op, struct expr *rhs);
  void print_expr(struct expr *expr);
  void emit_stack_machine(struct expr *expr);
  int emit_reg_machine(struct expr *expr);
  void free_expr(struct expr *expr);
  enum value_type check_types(struct expr *expr);
  const char *type_name(enum value_type t);
%}

%union {
  int value;
  size_t id;
  struct expr *expr;
  enum value_type {
    ERROR = -1,
    UNTYPED = 0,
    INTEGER = 1,
    BOOLEAN = 2,
  } type;
}

%token GE LE EQ NE FALSE TRUE
%token BOOL_TYPE INT_TYPE
%token <id> ID
%token <value> VAL
%type  <expr>  expr
%type  <type>  type

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'

%%
program:
    program decl '\n'   {}
    | program expr '\n' {
        enum value_type t = check_types($2);
        if (t != ERROR) {
          print_expr($2); printf(": %s\n\n", type_name(t));
          emit_stack_machine($2); printf("\n");
          printf("ret r%d\n\n", emit_reg_machine($2));
        } else {
          yyerror("The expression does not have a valid type\n");
          exit(0);
        }
        free_expr($2);
      }
    |
    ;

type: BOOL_TYPE   { $$ = BOOLEAN; }
      | INT_TYPE  { $$ = INTEGER; }

decl: type ID {
                if (vector_get(&global_types, $2)) {
                  printf("Multiple declarations for identifier %s\n", string_int_rev(&global_ids, $2));
                  exit(0);
                } else {
                  void *p = (void *) $1;
                  vector_set(&global_types, $2, p);
                }
              }

expr: VAL             { $$ = literal($1); }
      | FALSE         { $$ = bool_lit(0); }
      | TRUE          { $$ = bool_lit(1); }
      | ID            { $$ = variable($1); }
      | '(' expr ')'  { $$ = $2; }

      | expr '+' expr { $$ = binop($1, '+', $3); }
      | expr '-' expr { $$ = binop($1, '-', $3); }
      | expr '*' expr { $$ = binop($1, '*', $3); }
      | expr '/' expr { $$ = binop($1, '/', $3); }

      | expr EQ  expr { $$ = binop($1, EQ, $3); }
      | expr NE  expr { $$ = binop($1, NE, $3); }

      | expr GE  expr { $$ = binop($1, GE, $3); }
      | expr LE  expr { $$ = binop($1, LE, $3); }
      | expr '>' expr { $$ = binop($1, '>', $3); }
      | expr '<' expr { $$ = binop($1, '<', $3); }

      ;

%%

void yyerror(char* s){
    fprintf(stderr, "%s\n", s);
}

int main(void){
    vector_init(&global_types);
    string_int_init(&global_ids);
    yyparse();
    vector_fini(&global_types);
    string_int_fini(&global_ids);
    return 0;
}
