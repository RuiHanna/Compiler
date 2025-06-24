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

//函数调用声明
int handle_function(char* func_name, int arg_count, int* args);

%}

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


//指明非终结符类型
%type <ival> program stmt expr
%type <args> expr_list


%left '+' '-'
%left '*' '/'
%right UMINUS   // 一元减号优先级高于乘除加减


%% 

program:
    program stmt SEMICOLON
  | /* empty */          { $$ = 0; }
  ;

stmt:
    expr                        { $$ = $1; }
  | VAR '=' expr                { set_var($1, $3); $$ = $3; free($1); }
  | INT_TYPE VAR '=' expr       { set_var($2, $4); $$ = $4; free($2); }   // int 声明并初始化
  | INT_TYPE VAR                { set_var($2, 0); $$ = 0; free($2); }     // int 声明（不初始化）
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
  | '-' expr %prec UMINUS { $$ = -$2; }
  | '(' expr ')'  { $$ = $2; }
  | NUMBER        { $$ = $1; }
  // 函数调用规则
  | VAR '(' ')' { 
        $$ = handle_function($1, 0, NULL); 
        free($1); 
    }
  | VAR '(' expr_list ')' { 
        $$ = handle_function($1, $3.count, $3.args); 
        free($1);
        free($3.args);
    }
  | VAR  { $$ = get_var($1); free($1); }
  
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
    fprintf(stderr, "Syntax error at line %d: %s\n", curr_lineno, s);
}


