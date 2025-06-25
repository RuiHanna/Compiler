#ifndef AST_H
#define AST_H

typedef struct AST AST;

//符号表
typedef struct {
    char* name;
    int value;
    int arr_size;
    int* arr;
} Variable;

#define MAX_VARS 1024
extern Variable symtab[MAX_VARS];
extern int var_count;

// AST 节点类型枚举
typedef enum
{
    N_EXPR,   // 数值表达式（如 123）
    N_ASSIGN, // 赋值语句（如 a = 5）
    N_CALL,   // 函数调用（如 print(a)）
    N_IF,     // if 语句（无 else）
    N_IFELSE, // if-else 语句
    N_WHILE,  // while 循环
    N_FOR,    // for 循环
    N_BLOCK,  // 语句块（{} 内的语句序列）
    N_VAR,         // 变量引用
    N_ARRAY_DECL,   // 数组声明
    N_ARRAY_ACCESS, // 数组访问（如 a[1]）
    N_ARRAY_ASSIGN, // 数组赋值（如 a[1] = 5）

} NodeType;

// AST 结构体定义
typedef struct AST
{
    NodeType type;
    union
    {
        int expr_val; // 用于 N_EXPR（数值）
        struct
        {                     // 用于 N_ASSIGN（赋值）
            char *name;       // 变量名
            struct AST *expr; // 右侧表达式
        } assign;
        struct
        {                      // 用于 N_CALL（函数调用）
            char *name;        // 函数名
            int argc;          // 参数数量
            struct AST **argv; // 参数列表（AST 节点数组）
        } call;
        struct
        {                      // 用于 N_IF/N_IFELSE（条件语句）
            struct AST *cond;  // 条件表达式
            struct AST *thenb; // then 分支
            struct AST *elseb; // else 分支（可能为 NULL）
        } ifn;
        struct
        {                     // 用于 N_WHILE（while 循环）
            struct AST *cond; // 条件表达式
            struct AST *body; // 循环体
        } whilen;
        struct
        {                     // 用于 N_FOR（for 循环）
            struct AST *init; // 初始化语句
            struct AST *cond; // 条件表达式
            struct AST *upd;  // 更新语句
            struct AST *body; // 循环体
        } forn;
        struct
        {                       // 用于 N_BLOCK（语句块）
            struct AST **stmts; // 语句列表（AST 节点数组）
            int count;          // 语句数量
        } block;
        struct {
            char *name;
            int size;
        } array_decl;

        struct {
            char *name;
            AST *index;
            AST *value;
        } array_assign;

        struct {
            char *name;
            AST *index;
        } array_access;

        char *var_name; // 用于 N_VAR（变量引用）
    };
} AST;

// 工厂函数（在 ast.c 里实现）
AST *new_expr(int val);
AST *new_assign(char *name, AST *expr);
AST *new_print(AST *expr);
AST *new_call(char *name, int argc, AST **argv);
AST *new_if(AST *cond, AST *thenb);
AST *new_ifelse(AST *cond, AST *thenb, AST *elseb);
AST *new_while(AST *cond, AST *body);
AST *new_for(AST *init, AST *cond, AST *upd, AST *body);
AST *new_block(AST **stmts, int count);
AST *new_var(char *name);                    // 变量引用
AST *new_binop(char op, AST *lhs, AST *rhs); // 二元运算表达式
AST *new_unaryop(char op, AST *expr);        // 一元运算表达式（如负号）
AST *new_array_decl(char *name, AST *size);
AST *new_array_assign(char *name, AST *index, AST *value);
AST *new_array_access(char *name, AST *index);

// 遍历执行
int eval_ast(AST *node);
void exec_ast(AST *node);

// 释放内存
void free_ast(AST *node);

#endif // AST_H
