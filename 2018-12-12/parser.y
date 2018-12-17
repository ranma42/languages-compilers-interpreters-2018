%{
  #include <stdio.h>
  #include <stdlib.h>

  #include <llvm-c/Analysis.h>
  #include <llvm-c/Core.h>
  #include <llvm-c/ExecutionEngine.h>
  #include <llvm-c/IRReader.h>
  #include <llvm-c/Transforms/Scalar.h>
  #include <llvm-c/Transforms/Utils.h>

  #include "ast.h"
  #include "utils.h"

  int yylex(void);
  void yyerror(LLVMModuleRef module, LLVMBuilderRef builder, const char* s);
%}

%parse-param {LLVMModuleRef module}
%parse-param {LLVMBuilderRef builder}

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
                      if (valid_stmt($2)) {
                        codegen_stmt($2, module, builder);
                      } else {
                        fprintf(stderr, "INVALID PROGRAM\n");
                        exit(1);
                      }
                      // printf("{\n");
                      // print_stmt($2, 1);
                      // printf("}\n");
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
                          LLVMTypeRef t = $1 == BOOLEAN ? LLVMInt1Type() : LLVMInt32Type();
                          LLVMValueRef p = LLVMBuildAlloca(builder, t, string_int_rev(&global_ids, $2));
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

void yyerror(LLVMModuleRef module, LLVMBuilderRef builder, const char* s) {
    fprintf(stderr, "%s\n", s);
}

int main(void)
{
    LLVMModuleRef module = LLVMModuleCreateWithName("exe");
    LLVMBuilderRef builder = LLVMCreateBuilder();

    LLVMModuleRef runtime;
    char *error;
    LLVMMemoryBufferRef buffer;
    LLVMExecutionEngineRef engine;

    vector_init(&global_types);
    string_int_init(&global_ids);

    LLVMInitializeNativeTarget();
    LLVMInitializeNativeAsmPrinter();
    LLVMInitializeNativeAsmParser();
    LLVMLinkInMCJIT();

    // Create execution engine.
    if (LLVMCreateExecutionEngineForModule(&engine, module, &error)) {
      fprintf(stderr, "%s\n", error);
      return 1;
    } else if (LLVMCreateMemoryBufferWithContentsOfFile("runtime.bc", &buffer, &error)) {
      fprintf(stderr, "%s\n", error);
      return 1;
    } else if (LLVMParseIRInContext(LLVMGetGlobalContext(), buffer, &runtime, &error)) {
      fprintf(stderr, "%s\n", error);
      return 1;
    }

    // Setup optimizations.
    LLVMPassManagerRef pass_manager = LLVMCreateFunctionPassManagerForModule(module);
    LLVMAddPromoteMemoryToRegisterPass(pass_manager);
    LLVMInitializeFunctionPassManager(pass_manager);

    // print_i32
    LLVMTypeRef print_i32_args[] = { LLVMInt32Type() };
    LLVMAddFunction(module, "print_i32",
    LLVMFunctionType(LLVMVoidType(), print_i32_args, 1, 0));

    // print_i1
    LLVMTypeRef print_i1_args[] = { LLVMInt1Type() };
    LLVMAddFunction(module, "print_i1",
    LLVMFunctionType(LLVMVoidType(), print_i1_args, 1, 0));

    // create "main" function
    LLVMTypeRef main_type = LLVMFunctionType(LLVMVoidType(), NULL, 0, 0);
    LLVMValueRef main = LLVMAddFunction(module, "main", main_type);
    LLVMBasicBlockRef main_bb = LLVMAppendBasicBlock(main, "entry");
    LLVMPositionBuilderAtEnd(builder, main_bb);

    yyparse(module, builder);

    LLVMBuildRet(builder, 0);

    // Dump entire module.
    LLVMDumpModule(module);

    LLVMVerifyModule(module, LLVMAbortProcessAction, &error);

    LLVMRunFunctionPassManager(pass_manager, main);

    // Dump entire module.
    LLVMDumpModule(module);

    fprintf(stderr, "Generating code\n");
    void (*main_fn)() = (void (*)()) LLVMGetPointerToGlobal(engine, main);
    fprintf(stderr, "Running\n");
    main_fn();
    fprintf(stderr, "Done\n");

    vector_fini(&global_types);
    string_int_fini(&global_ids);

    LLVMDisposeBuilder(builder);
    LLVMDisposeModule(module);

    return 0;
}
