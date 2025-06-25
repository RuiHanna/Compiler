%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <math.h>

extern int curr_lineno;
void yyerror(const char *s);
int yylex();

//定义符号表
#define MAX_VARS 1024
typedef struct {
    char* name;
    int value;
} Variable;

Variable symtab[MAX_VARS];
int var_count = 0;//符号表中变量计数

//获取变量值
int get_var(const char* name) {
    for (int i = 0; i < var_count; ++i) {
        if (strcmp(symtab[i].name, name) == 0)
            return symtab[i].value;
    }
    fprintf(stderr, "Undefined variable: %s\n", name);
    return 0;
}

//设置变量值
void set_var(const char* name, int value) {
    for (int i = 0; i < var_count; ++i) {
        if (strcmp(symtab[i].name, name) == 0) {
            symtab[i].value = value;
            return;
        }
    }
    symtab[var_count].name = strdup(name);
    symtab[var_count].value = value;
    var_count++;
}

//声明
int handle_function(char* func_name, int arg_count, int* args);
void execute_stmt(int stmt_value);
int evaluate_expr(int expr_value);
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
    struct {
        int count;
        int* args;
    } args;          // 参数列表结构
}

%token <name> VAR    // 变量名
%token <ival> NUMBER // 数值
%token EOL //end of line
%token INT_TYPE //int变量声明
%token SEMICOLON //分号
%token IF ELSE WHILE FOR// 控制结构token声明
%token LE GE EQ NEQ // 关系运算符


//指明非终结符类型
%type <ival> program stmt expr
%type <args> expr_list
%type <ival> block optional_stmts stmt_list for_init for_update
%type <ival> expr_stmt assign_stmt decl_stmt ctrl_stmt primary_expr


%left '+' '-'
%left '*' '/'
%left '<' '>' LE GE EQ NEQ // 关系运算符优先级低于加减乘除
%right UMINUS   // 一元减号优先级高于乘除加减
%left ';'


%% 

program:
    stmt_list
  ;

stmt_list:
    stmt           { $$ = 0; }   // 空语句列表
  | stmt_list stmt    { $$ = $2; }  // 语句列表 + 可选分号语句
  ;

stmt:
    expr_stmt
  | assign_stmt
  | decl_stmt
  | ctrl_stmt
  | block
  ;

expr_stmt:
    expr SEMICOLON { $$ = $1; }
  ;

assign_stmt:
    VAR '=' expr SEMICOLON { set_var($1, $3); $$ = $3; free($1); }
  ;

decl_stmt:
    INT_TYPE VAR SEMICOLON              { set_var($2, 0); $$ = 0; free($2); }
  | INT_TYPE VAR '=' expr SEMICOLON     { set_var($2, $4); $$ = $4; free($2); }
  ;

ctrl_stmt:
    IF '(' expr ')' stmt %prec IF { 
        if ($3) {
            execute_stmt($5);
        }
        $$ = 0; 
    }
  | IF '(' expr ')' stmt ELSE stmt %prec ELSE {
        if ($3) {
            execute_stmt($5);
        }else{
            execute_stmt($7);
        }
        $$ = 0;
    }
  | WHILE '(' expr ')' stmt {
        while( $3 ){
            execute_stmt($5);
            $3 = evaluate_expr($3);
        }
        $$ = 0;
  }
  | FOR '(' for_init ';' expr ';' for_update ')' stmt {
        execute_stmt($3); 
            while ($5) {
                execute_stmt($9);
                execute_stmt($7);
                $5 = evaluate_expr($5);
            }
        $$ = 0; 
  }
  ;

block:
    '{' optional_stmts '}' { $$ = $2; }
  ;

optional_stmts:
    stmt_list
  | /* empty */ { $$=0; }
  ;

// for循环初始化
for_init:
    expr                        { $$ = $1; }  // 赋值表达式（如i=0）
  | INT_TYPE VAR '=' expr       { set_var($2, $4); free($2); $$ = $4; }  // 声明并初始化（如int i=0）
  | INT_TYPE VAR                { set_var($2, 0); free($2); $$ = 0; }    // 声明未初始化（如int i）
  ;

// for循环更新
for_update:
    expr { $$ = $1; }  // 如i++、i=i+1等
  ;
  
expr:
    expr '+' expr { $$ = $1 + $3; }
  | expr '-' expr { $$ = $1 - $3; }
  | expr '*' expr { $$ = $1 * $3; }
  | expr '/' expr {
        if ($3 == 0) {
            yyerror("Division by zero");
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
  | expr '<' expr   { $$ = ($1 < $3) ? 1 : 0; }  // 小于
  | expr '>' expr   { $$ = ($1 > $3) ? 1 : 0; }  // 大于
  | expr LE expr    { $$ = ($1 <= $3) ? 1 : 0; }  // 小于等于
  | expr GE expr    { $$ = ($1 >= $3) ? 1 : 0; }  // 大于等于
  | expr EQ expr    { $$ = ($1 == $3) ? 1 : 0; }  // 等于
  | expr NEQ expr   { $$ = ($1 != $3) ? 1 : 0; }  // 不等于
  | '-' expr %prec UMINUS { $$ = -$2; }
  | '(' expr ')'  { $$ = $2; }
  | primary_expr
  ;

primary_expr:
    VAR  { $$ = get_var($1); free($1); }
  // 函数调用
  | VAR '(' ')' { 
        $$ = handle_function($1, 0, NULL); 
        free($1); 
    }
  | VAR '(' expr_list ')' { 
        $$ = handle_function($1, $3.count, $3.args); 
        free($1);
        free($3.args);
    }
  | NUMBER        { $$ = $1; }
  ;

// 参数列表规则
expr_list:
    expr { 
        $$.count = 1;
        $$.args = malloc(sizeof(int));
        $$.args[0] = $1;
    }

  | expr_list ',' expr { 
        $$.count = $1.count + 1;
        $$.args = realloc($1.args, $$.count * sizeof(int));
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
        printf("%d\n", args[0]);
        return args[0];  // 你也可以返回 0 或 void 类型模拟效果
    }
    // 添加更多函数...
    else {
        yyerror("Unknown function");
        return 0;
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylloc.first_line, s);  // 使用位置起始行号
}


