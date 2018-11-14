#include <stdio.h>
#include <stdlib.h>

enum expr_type {
  LITERAL,
  VARIABLE,
  BIN_OP,
};

struct expr {
  enum expr_type type;
  union {
    int value; // for type == LITERAL
    char *id; // for type == VARIABLE
    struct {
      struct expr *lhs;
      struct expr *rhs;
      char op;
    } binop; // for type == BIN_OP
  };
};

struct expr* literal(int v) {
  struct expr* r = malloc(sizeof(struct expr));
  r->type = LITERAL;
  r->value = v;
  return r;
}

struct expr* variable(char *id) {
  struct expr* r = malloc(sizeof(struct expr));
  r->type = VARIABLE;
  r->id = id;
  return r;
}

struct expr* binop(struct expr *lhs, char op, struct expr *rhs) {
  struct expr* r = malloc(sizeof(struct expr));
  r->type = BIN_OP;
  r->binop.lhs = lhs;
  r->binop.op = op;
  r->binop.rhs = rhs;
  return r;
}

void print_expr(struct expr *expr) {
  switch (expr->type) {
    case LITERAL:
      printf("%d", expr->value);
      break;

    case VARIABLE:
      printf("%s", expr->id);
      break;

    case BIN_OP:
      printf("(");
      print_expr(expr->binop.lhs);
      printf(" %c ", expr->binop.op);
      print_expr(expr->binop.rhs);
      printf(")");
      break;
  }
}

void emit_stack_machine(struct expr *expr) {
  switch (expr->type) {
    case LITERAL:
      printf("load_imm %d\n", expr->value);
      break;

    case VARIABLE:
      printf("load_mem %s\n", expr->id);
      break;

    case BIN_OP:
      emit_stack_machine(expr->binop.lhs);
      emit_stack_machine(expr->binop.rhs);
      switch (expr->binop.op) {
        case '+': printf("add\n"); break;
        case '-': printf("sub\n"); break;
        case '*': printf("mul\n"); break;
        case '/': printf("div\n"); break;
      }
      break;
  }
}

static int next_reg = 0;

int gen_reg() {
  return next_reg++;
}

int emit_reg_machine(struct expr *expr) {
  int result_reg = gen_reg();
  switch (expr->type) {
    case LITERAL:
      printf("r%d = %d\n", result_reg, expr->value);
      break;

    case VARIABLE:
      printf("r%d = %s\n", result_reg, expr->id);
      break;

    case BIN_OP: {
      int lhs = emit_reg_machine(expr->binop.lhs);
      int rhs = emit_reg_machine(expr->binop.rhs);
      switch (expr->binop.op) {
        case '+': printf("r%d = add r%d, r%d\n", result_reg, lhs, rhs); break;
        case '-': printf("r%d = sub r%d, r%d\n", result_reg, lhs, rhs); break;
        case '*': printf("r%d = mul r%d, r%d\n", result_reg, lhs, rhs); break;
        case '/': printf("r%d = div r%d, r%d\n", result_reg, lhs, rhs); break;
      }
      break;
    }
  }
  return result_reg;
}

void free_expr(struct expr *expr) {
  switch (expr->type) {
    case LITERAL:
      free(expr);
      break;

    case VARIABLE:
      free(expr->id);
      free(expr);
      break;

    case BIN_OP:
      free_expr(expr->binop.lhs);
      free_expr(expr->binop.rhs);
      free(expr);
      break;
  }
}
