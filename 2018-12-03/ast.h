#include <stdlib.h>

#include "expr-grammar.tab.h"

const char *type_name(enum value_type t);

enum expr_type {
  BOOL_LIT,
  LITERAL,
  VARIABLE,
  BIN_OP,
};

struct expr {
  enum expr_type type;
  union {
    int value; // for type == LITERAL || type == BOOL_LIT
    size_t id; // for type == VARIABLE
    struct {
      struct expr *lhs;
      struct expr *rhs;
      int op;
    } binop; // for type == BIN_OP
  };
};

struct expr* bool_lit(int v);
struct expr* literal(int v);
struct expr* variable(size_t id);
struct expr* binop(struct expr *lhs, int op, struct expr *rhs);

void print_expr(struct expr *expr);
void emit_stack_machine(struct expr *expr);
int emit_reg_machine(struct expr *expr);

enum value_type check_types(struct expr *expr);

void free_expr(struct expr *expr);
