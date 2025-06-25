%{
#include "ast.h"
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include <limits.h>

extern int curr_lineno;
void yyerror(const char *s);
int yylex();

//获取变量值
int get_var(const char* name) {
    // printf("[get_var] 查找变量: %s\n", name);
    for (int i = 0; i < var_count; ++i) {
        if (strcmp(symtab[i].name, name) == 0)
            return symtab[i].value;
    }
    fprintf(stderr, "Undefined variable: %s\n", name);
    exit(1); // 调试阶段直接退出
    return INT_MIN; // 用最小整数表示未定义
}

//设置变量值
void set_var(const char* name, int value) {
    // printf("[set_var] 设置变量: %s = %d\n", name, value);
    for (int i = 0; i < var_count; ++i) {
        if (strcmp(symtab[i].name, name) == 0) {
            symtab[i].value = value;
            return;
        }
    }
    if (var_count >= MAX_VARS) {
        fprintf(stderr, "符号表已满，无法添加变量: %s\n", name);
        exit(1);
    }
    symtab[var_count].name = strdup(name);
    symtab[var_count].value = value;
    symtab[var_count].arr = NULL;
    symtab[var_count].arr_size = 0;
    var_count++;
    // printf("  新增变量: %s, var_count=%d\n", name, var_count);
}

//声明
int handle_function(char* func_name, int arg_count, int* args);
void execute_stmt(int stmt_value);
int evaluate_expr(int expr_value);

AST *root;
%}

%locations
%define parse.error verbose

// 通过非关联优先级解决dangling else冲突
%nonassoc IF
%nonassoc ELSE

//类型定义与声明区域
%union {
    int ival;   //数值
    char* name;      // 变量名
    ASTList args;
    AST* node;
}

%token <name> VAR    // 变量名
%token <ival> NUMBER // 数值
%token EOL //end of line
%token INT_TYPE //int变量声明
%token SEMICOLON //分号
%token IF ELSE WHILE FOR// 控制结构token声明
%token LE GE EQ NEQ // 关系运算符
%token INC_OP DEC_OP ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN


//指明非终结符类型
%type <node> program stmt stmt_list expr_stmt decl_stmt ctrl_stmt block
%type <node> expr
%type <node> primary_expr
%type <args> expr_list
%type <node> for_init for_update
%type <args> init_list
%type <args> var_decl_list
%type <node> var_decl


%right '=' ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN
%left '+' '-'
%left '*' '/'
%right INC_OP DEC_OP
%left '<' '>' LE GE EQ NEQ
%right UMINUS
%left ';'


%% 

program:
    stmt_list { root = $1; }
  ;

stmt_list:
    /* empty */    { $$ = new_block(NULL, 0); }
  | stmt_list stmt { 
        if ($2 != NULL) {
            int old = $1->block.count;
            $1->block.stmts = realloc($1->block.stmts, sizeof(AST*)*(old+1));
            $1->block.stmts[old] = $2;
            $1->block.count = old+1;
        }
        $$ = $1;
    }
  ;

stmt:
    expr_stmt      { $$ = $1; }
  | VAR INC_OP SEMICOLON { 
        $$ = new_incdec($1, 1);  // 生成 AST 节点，不立即执行
    }
  | VAR DEC_OP SEMICOLON { 
        $$ = new_incdec($1, -1); // 生成 AST 节点，不立即执行
    }
  | decl_stmt      { $$ = $1; }
  | ctrl_stmt      { $$ = $1; }
  | block          { $$ = $1; }
  ;

expr_stmt:
    expr SEMICOLON { $$ = $1; }
  ;

decl_stmt:
    INT_TYPE var_decl_list SEMICOLON {
        // 生成一个 block，把所有声明语句串起来
        $$ = new_block($2.args, $2.count);
    }
  ;

var_decl_list:
    var_decl {
        $$.count = 1;
        $$.args = malloc(sizeof(AST*));
        $$.args[0] = $1;
    }
  | var_decl_list ',' var_decl {
        $$.count = $1.count + 1;
        $$.args = realloc($1.args, $$.count * sizeof(AST*));
        $$.args[$$.count - 1] = $3;
    }
  ;

var_decl:
    VAR {
        $$ = new_assign($1, new_expr(0));
    }
  | VAR '=' expr {
        $$ = new_assign($1, $3);
    }
  | VAR '[' expr ']' {
        $$ = new_array_decl($1, $3);
    }
  | VAR '[' expr ']' '=' '{' init_list '}' {
        $$ = new_array_decl_init($1, $3, $7);
    }
  ;

ctrl_stmt:
    IF '(' expr ')' stmt %prec IF {
      $$ = new_if($3, $5);
    }
  | IF '(' expr ')' stmt ELSE stmt %prec ELSE {
      $$ = new_ifelse($3, $5, $7);
    }
  | WHILE '(' expr ')' stmt {
      $$ = new_while($3, $5);
    }
  | FOR '(' for_init SEMICOLON expr SEMICOLON for_update ')' stmt {
      $$ = new_for($3, $5, $7, $9);
    }
  ;

block:
    '{' stmt_list '}' { $$ = $2; }
  ;

for_init:
      /* empty */           { $$ = new_block(NULL, 0); }
    | INT_TYPE VAR          { $$ = new_assign($2, new_expr(0)); }
    | INT_TYPE VAR '=' expr { $$ = new_assign($2, $4); }
    | expr                  { $$ = $1; }
    | VAR INC_OP            { $$ = new_incdec($1, 1); }
    | VAR DEC_OP            { $$ = new_incdec($1, -1); }
    ;

for_update:
      /* empty */           { $$ = new_block(NULL, 0); }
    | expr                  { $$ = $1; }
    | VAR INC_OP            { $$ = new_incdec($1, 1); }
    | VAR DEC_OP            { $$ = new_incdec($1, -1); }
    ;
  
expr:
    VAR '[' expr ']' '=' expr %prec '=' { $$ = new_array_assign($1, $3, $6); }
  | VAR '=' expr %prec '=' { $$ = new_assign($1, $3); }
  | expr '+' expr { $$ = new_binop('+', $1, $3); }
  | expr '-' expr { $$ = new_binop('-', $1, $3); }
  | expr '*' expr { $$ = new_binop('*', $1, $3); }
  | expr '/' expr { $$ = new_binop('/', $1, $3); }
  | expr '<' expr { $$ = new_binop('<', $1, $3); }
  | expr '>' expr { $$ = new_binop('>', $1, $3); }
  | expr LE expr  { $$ = new_call("LE", 2, (AST*[]){$1, $3}); }
  | expr GE expr  { $$ = new_call("GE", 2, (AST*[]){$1, $3}); }
  | expr EQ expr  { $$ = new_call("EQ", 2, (AST*[]){$1, $3}); }
  | expr NEQ expr { $$ = new_call("NEQ", 2, (AST*[]){$1, $3}); }
  | VAR ADD_ASSIGN expr %prec ADD_ASSIGN { $$ = new_comp_assign($1, "+", $3); }
  | VAR SUB_ASSIGN expr %prec SUB_ASSIGN { $$ = new_comp_assign($1, "-", $3); }
  | VAR MUL_ASSIGN expr %prec MUL_ASSIGN { $$ = new_comp_assign($1, "*", $3); }
  | VAR DIV_ASSIGN expr %prec DIV_ASSIGN { $$ = new_comp_assign($1, "/", $3); }
  | '-' expr %prec UMINUS { $$ = new_unaryop('-', $2); }
  | '(' expr ')'          { $$ = $2; }
  | primary_expr          { $$ = $1; }
;


primary_expr:
    VAR  { $$ = new_var($1);  }
  | VAR '[' expr ']' { $$ = new_array_access($1, $3); }
  | NUMBER        { $$ = new_expr($1); }
  | VAR '(' ')' {
        $$ = new_call($1, 0, NULL);
    }
  | VAR '(' expr_list ')' {
        AST **args = malloc(sizeof(AST*) * $3.count);
        for (int i = 0; i < $3.count; i++) {
            args[i] = $3.args[i];
        }
        $$ = new_call($1, $3.count, args);
    }
;


// 参数列表规则
expr_list:
    expr { 
        $$.count = 1;
        $$.args = malloc(sizeof(AST*));
        $$.args[0] = $1;
    }

  | expr_list ',' expr { 
        $$.count = $1.count + 1;
        $$.args = realloc($1.args, $$.count * sizeof(AST*));
        $$.args[$$.count - 1] = $3;
    }
  ;

init_list:
    expr {
        $$.count = 1;
        $$.args = malloc(sizeof(AST*));
        $$.args[0] = $1;
    }
  | init_list ',' expr {
        $$.count = $1.count + 1;
        $$.args = realloc($1.args, $$.count * sizeof(AST*));
        $$.args[$$.count - 1] = $3;
    }
  ;

%%

//执行语句
void execute_stmt(int stmt_value) {
    return;
}

int evaluate_expr(int expr_value){
    return expr_value;
}

// 函数处理实现
int handle_function(char* func_name, int arg_count, int* args) {
    if (strcmp(func_name, "sqrt") == 0) {
        if (arg_count != 1) {
            yyerror("sqrt function needs 1 arguments");
            return 0;
        }
        return (int)sqrt(args[0]);
    }else if (strcmp(func_name, "pow") == 0) {
        if (arg_count != 2) {
            yyerror("pow function needs 2 arguments");
            return 0;
        }
        return (int)pow(args[0], args[1]);
    }else if (strcmp(func_name, "print") == 0) {
        if (arg_count != 1) {
            yyerror("print function needs 1 argument");
            return 0;
        }
        if (args[0] == INT_MIN) {
            // 不输出
            return 0;
        }
        printf("%d\n", args[0]);
        return 0;
    }else if (strcmp(func_name, "<") == 0) {
        if (arg_count != 2) {
            yyerror("< operator needs 2 arguments");
            return 0;
        }
        return args[0] < args[1];
    } else if (strcmp(func_name, ">") == 0) {
        if (arg_count != 2) {
            yyerror("> operator needs 2 arguments");
            return 0;
        }
        return args[0] > args[1];
    }else if (strcmp(func_name, "+") == 0) {
        if (arg_count != 2) {
            yyerror("+ operator needs 2 arguments");
            return 0;
        }
        return args[0] + args[1];
    } else if (strcmp(func_name, "-") == 0) {
        if (arg_count == 2) {
            return args[0] - args[1];
        } else if (arg_count == 1) {
            return -args[0];
        } else {
            yyerror("- operator needs 1 or 2 arguments");
            return 0;
        }
    } else if (strcmp(func_name, "*") == 0) {
        if (arg_count != 2) {
            yyerror("* operator needs 2 arguments");
            return 0;
        }
        return args[0] * args[1];
    } else if (strcmp(func_name, "/") == 0) {
        if (arg_count != 2) {
            yyerror("/ operator needs 2 arguments");
            return 0;
        }
        if (args[1] == 0) {
            yyerror("division by zero");
            return INT_MIN;
        }
        return args[0] / args[1];
    }else if (strcmp(func_name, "EQ") == 0) {
        if (arg_count != 2) {
            yyerror("EQ operator needs 2 arguments");
            return 0;
        }
        return args[0] == args[1];
    } else if (strcmp(func_name, "NEQ") == 0) {
        if (arg_count != 2) {
            yyerror("NEQ operator needs 2 arguments");
            return 0;
        }
        return args[0] != args[1];
    } else if (strcmp(func_name, "LE") == 0) {
        if (arg_count != 2) {
            yyerror("LE operator needs 2 arguments");
            return 0;
        }
        return args[0] <= args[1];
    } else if (strcmp(func_name, "GE") == 0) {
        if (arg_count != 2) {
            yyerror("GE operator needs 2 arguments");
            return 0;
        }
        return args[0] >= args[1];
    }else if (strcmp(func_name, "++") == 0) {
        if (arg_count != 1) {
            yyerror("++ operator needs 1 argument");
            return 0;
        }
         yyerror("++/-- 仅支持作为语句出现，且实现需调整");
        return 0;
    } else if (strcmp(func_name, "--") == 0) {
        if (arg_count != 1) {
            yyerror("-- operator needs 1 argument");
            return 0;
        }
         yyerror("++/-- 仅支持作为语句出现，且实现需调整");
        return 0;
    }
    // 添加更多函数...
    else {
        char msg[128];
        snprintf(msg, sizeof(msg), "Unknown function: %s", func_name);
        yyerror(msg);
        return 0;
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylloc.first_line, s);  // 使用位置起始行号
}

