#include <stdio.h>
#include <stdlib.h>

#include "ast.h"
#include "y.tab.h"
#include "utils.h"

const char *type_name(enum value_type t) {
  switch (t) {
    case INTEGER: return "int";
    case BOOLEAN: return "bool";
    case ERROR: return "error";
    default: return "not-a-type";
  }
}

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

struct expr* variable(size_t id) {
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
      printf("%s", string_int_rev(&global_ids, expr->id));
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
      printf("load_mem %zu # %s\n", expr->id, string_int_rev(&global_ids, expr->id));
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

static int gen_reg() {
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
      printf("r%d = load %zu # %s\n", result_reg, expr->id, string_int_rev(&global_ids, expr->id));
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
      return (enum value_type) vector_get(&global_types, expr->id);

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
    case VARIABLE:
      free(expr);
      break;

    case BIN_OP:
      free_expr(expr->binop.lhs);
      free_expr(expr->binop.rhs);
      free(expr);
      break;
  }
}

struct stmt* make_seq(struct stmt *fst, struct stmt *snd) {
  struct stmt* r = malloc(sizeof(struct stmt));
  r->type = STMT_SEQ;
  r->seq.fst = fst;
  return r;
}

struct stmt* make_assign(size_t id, struct expr *e) {
  struct stmt* r = malloc(sizeof(struct stmt));
  r->type = STMT_ASSIGN;
  r->assign.id = id;
  r->assign.expr = e;
  return r;
}

struct stmt* make_while(struct expr *e, struct stmt *body) {
  struct stmt* r = malloc(sizeof(struct stmt));
  r->type = STMT_WHILE;
  r->while_.cond = e;
  r->while_.body = body;
  return r;
}

struct stmt* make_ifelse(struct expr *e, struct stmt *if_body, struct stmt *else_body) {
  struct stmt* r = malloc(sizeof(struct stmt));
  r->type = STMT_IF;
  r->ifelse.cond = e;
  r->ifelse.if_body = if_body;
  r->ifelse.else_body = else_body;
  return r;
}

struct stmt* make_if(struct expr *e, struct stmt *body) {
  return make_ifelse(e, body, NULL);
}

struct stmt* make_print(struct expr *e) {
  struct stmt* r = malloc(sizeof(struct stmt));
  r->type = STMT_PRINT;
  r->print.expr = e;
  return r;
}

void free_stmt(struct stmt *stmt) {
  switch (stmt->type) {
    case STMT_SEQ:
      free_stmt(stmt->seq.fst);
      free_stmt(stmt->seq.snd);
      break;

    case STMT_ASSIGN:
      free_expr(stmt->assign.expr);
      break;

    case STMT_PRINT:
      free_expr(stmt->print.expr);
      break;

    case STMT_WHILE:
      free_expr(stmt->while_.cond);
      free_stmt(stmt->while_.body);
      break;

    case STMT_IF:
      free_expr(stmt->ifelse.cond);
      free_stmt(stmt->ifelse.if_body);
      if (stmt->ifelse.else_body)
        free_stmt(stmt->ifelse.else_body);
      break;
  }

  free(stmt);
}
