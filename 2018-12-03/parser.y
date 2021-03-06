%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "ast.h"
  #include "utils.h"

  int yylex(void);
  void yyerror(const char *);
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
  struct stmt *stmt;
}

%token GE LE EQ NE
%token FALSE TRUE
%token IF ELSE WHILE PRINT
%token BOOL_TYPE INT_TYPE
%token <id> ID
%token <value> VAL
%type  <expr>  expr
%type  <stmt>  stmt
%type  <stmt>  stmts
%type  <type>  type

%nonassoc IF_ALONE
%nonassoc ELSE
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'

%%
program: decls stmt {
                      free_stmt($2);
                    }

type: BOOL_TYPE   { $$ = BOOLEAN; }
      | INT_TYPE  { $$ = INTEGER; }

decls: decls decl | ;
decl: type ID ';'     {
                        if (vector_get(&global_types, $2)) {
                          printf("Multiple declarations for identifier %s\n", string_int_rev(&global_ids, $2));
                          exit(0);
                        } else {
                          void *p = (void *) $1;
                          vector_set(&global_types, $2, p);
                        }
                      }

stmts: stmts stmt     { $$ = make_seq($1, $2); }
      | stmt          { $$ = $1; };

stmt: '{' stmts '}'                         { $$ = $2; }
      | ID '=' expr ';'                     { $$ = make_assign($1, $3); }
      | IF '(' expr ')' stmt %prec IF_ALONE { $$ = make_if($3, $5); }
      | IF '(' expr ')' stmt ELSE stmt      { $$ = make_ifelse($3, $5, $7); }
      | WHILE '(' expr ')' stmt             { $$ = make_while($3, $5); }
      | PRINT expr ';'                      { $$ = make_print($2); }

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

void yyerror(const char* s){
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
