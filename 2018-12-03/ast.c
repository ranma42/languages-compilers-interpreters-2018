#include <stdio.h>
#include <stdlib.h>

#include "expr-grammar.tab.h"

const char *type_name(enum value_type t) {
  switch (t) {
    case INTEGER: return "int";
    case BOOLEAN: return "bool";
    case ERROR: return "error";
    default: return "not-a-type";
  }
}

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
    char *id; // for type == VARIABLE
    struct {
      struct expr *lhs;
      struct expr *rhs;
      int op;
    } binop; // for type == BIN_OP
  };
};

struct expr* bool_lit(int v) {
  struct expr* r = malloc(sizeof(struct expr));
  r->type = BOOL_LIT;
  r->value = v;
  return r;
}

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

struct expr* binop(struct expr *lhs, int op, struct expr *rhs) {
  struct expr* r = malloc(sizeof(struct expr));
  r->type = BIN_OP;
  r->binop.lhs = lhs;
  r->binop.op = op;
  r->binop.rhs = rhs;
  return r;
}

void print_expr(struct expr *expr) {
  switch (expr->type) {
    case BOOL_LIT:
      printf("%s", expr->value ? "true" : "false");
      break;

    case LITERAL:
      printf("%d", expr->value);
      break;

    case VARIABLE:
      printf("%s", expr->id);
      break;

    case BIN_OP:
      printf("(");
      print_expr(expr->binop.lhs);
      switch (expr->binop.op) {
        case EQ: printf(" == "); break;
        case NE: printf(" != "); break;
        case GE: printf(" >= "); break;
        case LE: printf(" <= "); break;
        default: printf(" %c ", expr->binop.op); break;
      }
      print_expr(expr->binop.rhs);
      printf(")");
      break;
  }
}

void emit_stack_machine(struct expr *expr) {
  switch (expr->type) {
    case BOOL_LIT:
      printf(expr->value ? "load_true\n" : "load_false\n");
      break;

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

        case EQ: printf("eq\n"); break;
        case NE: printf("ne\n"); break;

        case GE: printf("ge\n"); break;
        case LE: printf("le\n"); break;
        case '>': printf("gt\n"); break;
        case '<': printf("lt\n"); break;
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
    case BOOL_LIT:
      printf("r%d = %d\n", result_reg, expr->value);
      break;

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

        case EQ: printf("r%d = eq r%d, r%d\n", result_reg, lhs, rhs); break;
        case NE: printf("r%d = ne r%d, r%d\n", result_reg, lhs, rhs); break;

        case GE: printf("r%d = ge r%d, r%d\n", result_reg, lhs, rhs); break;
        case LE: printf("r%d = le r%d, r%d\n", result_reg, lhs, rhs); break;
        case '>': printf("r%d = gt r%d, r%d\n", result_reg, lhs, rhs); break;
        case '<': printf("r%d = lt r%d, r%d\n", result_reg, lhs, rhs); break;
      }
      break;
    }
  }
  return result_reg;
}

enum value_type check_types(struct expr *expr) {
  switch (expr->type) {
    case BOOL_LIT:
      return BOOLEAN;

    case LITERAL:
      return INTEGER;

    case VARIABLE:
      printf("TODO\n");
      return ERROR;

    case BIN_OP: {
      enum value_type lhs = check_types(expr->binop.lhs);
      enum value_type rhs = check_types(expr->binop.rhs);
      switch (expr->binop.op) {
        case '+':
        case '-':
        case '*':
        case '/':
          if (lhs == INTEGER && rhs == INTEGER)
            return INTEGER;
          else
            return ERROR;

        case EQ:
        case NE:
          if (lhs == rhs && lhs != ERROR)
            return BOOLEAN;
          else
            return ERROR;

        case GE:
        case LE:
        case '>':
        case '<':
          if (lhs == INTEGER && rhs == INTEGER)
            return BOOLEAN;
          else
            return ERROR;

      }

      default:
        return ERROR;
    }
  }
}

void free_expr(struct expr *expr) {
  switch (expr->type) {
    case BOOL_LIT:
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
