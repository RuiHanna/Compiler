#include "ast.h"
#include "parser.tab.h" // 如果需要 token 定义 或 yylval
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

extern int var_count;
extern Variable symtab[];

int get_var(const char* name);
void set_var(const char* name, int value);
int handle_function(char* func_name, int arg_count, int* args);
void set_array(const char* name, int size);
void set_array_elem(const char* name, int idx, int value);
int get_array_elem(const char* name, int idx);

// 以下仅示意：实际要 malloc 并填充字段
AST *new_expr(int val)
{
    AST *n = malloc(sizeof *n);
    n->type = N_EXPR;
    n->expr_val = val;
    return n;
}

AST *new_assign(char *name, AST *expr)
{
    AST *n = malloc(sizeof *n);
    n->type = N_ASSIGN;
    n->assign.name = name;
    n->assign.expr = expr;
    return n;
}
// ... 其余 new_* 同理

AST *new_call(char *name, int argc, AST **argv)
{
    AST *n = malloc(sizeof(*n));
    n->type = N_CALL;
    n->call.name = strdup(name);
    n->call.argc = argc;
    n->call.argv = malloc(sizeof(AST *) * argc);
    for (int i = 0; i < argc; i++)
    {
        n->call.argv[i] = argv[i];
    }
    return n;
}

// 构造 if 语句（无 else）
AST *new_if(AST *cond, AST *thenb)
{
    AST *n = malloc(sizeof(AST));
    n->type = N_IF;
    n->ifn.cond = cond;
    n->ifn.thenb = thenb;
    n->ifn.elseb = NULL;
    return n;
}

// 构造 if-else 语句
AST *new_ifelse(AST *cond, AST *thenb, AST *elseb)
{
    AST *n = malloc(sizeof(AST));
    n->type = N_IFELSE;
    n->ifn.cond = cond;
    n->ifn.thenb = thenb;
    n->ifn.elseb = elseb;
    return n;
}

// 构造 while 语句
AST *new_while(AST *cond, AST *body)
{
    AST *n = malloc(sizeof(AST));
    n->type = N_WHILE;
    n->whilen.cond = cond;
    n->whilen.body = body;
    return n;
}

// 构造 for 语句
AST *new_for(AST *init, AST *cond, AST *upd, AST *body)
{
    AST *n = malloc(sizeof(AST));
    n->type = N_FOR;
    n->forn.init = init;
    n->forn.cond = cond;
    n->forn.upd = upd;
    n->forn.body = body;
    return n;
}

// 构造 block 语句（语句序列）
AST *new_block(AST **stmts, int count)
{
    AST *n = malloc(sizeof(AST));
    n->type = N_BLOCK;
    n->block.stmts = stmts;
    n->block.count = count;
    return n;
}

int eval_ast(AST *node)
{
    switch (node->type)
    {
    case N_EXPR:
        return node->expr_val;
    case N_ASSIGN:
    {
        int v = eval_ast(node->assign.expr);
        set_var(node->assign.name, v);
        return v;
    }
    case N_CALL:
    {
        int *args = malloc(sizeof(int) * node->call.argc);
        for (int i = 0; i < node->call.argc; i++)
        {
            args[i] = eval_ast(node->call.argv[i]);
        }
        int ret = handle_function(node->call.name, node->call.argc, args);
        free(args);
        return ret;
    }
    case N_VAR:
        return get_var(node->var_name);
    case N_ARRAY_DECL:
        set_array(node->array_decl.name, node->array_decl.size);
        if (node->array_decl.init_list) {
            for (int i = 0; i < node->array_decl.init_list->count && i < node->array_decl.size; ++i) {
                set_array_elem(node->array_decl.name, i, eval_ast(node->array_decl.init_list->args[i]));
            }
        }
        break;
    case N_ARRAY_ASSIGN:
        set_array_elem(node->array_assign.name, eval_ast(node->array_assign.index), eval_ast(node->array_assign.value));
        break;
    case N_ARRAY_ACCESS:
        return get_array_elem(node->array_access.name, eval_ast(node->array_access.index));
    default:
        return 0;
    }
}

void exec_ast(AST *node)
{
    switch (node->type)
    {
    case N_IF:
        if (eval_ast(node->ifn.cond))
            exec_ast(node->ifn.thenb);
        break;
    case N_IFELSE:
        if (eval_ast(node->ifn.cond))
            exec_ast(node->ifn.thenb);
        else
            exec_ast(node->ifn.elseb);
        break;
    case N_WHILE:
        while (eval_ast(node->whilen.cond))
            exec_ast(node->whilen.body);
        break;
    case N_FOR:
        eval_ast(node->forn.init);
        while (eval_ast(node->forn.cond))
        {
            exec_ast(node->forn.body);
            eval_ast(node->forn.upd);
        }
        break;
    case N_BLOCK:
        for (int i = 0; i < node->block.count; i++)
            exec_ast(node->block.stmts[i]);
        break;
    case N_ARRAY_DECL:
    case N_ARRAY_ASSIGN:
        eval_ast(node);
        break;
    // 赋值和函数调用都是表达式，直接 eval
    case N_EXPR:
    case N_ASSIGN:
    case N_CALL:
        eval_ast(node);
        break;
    }
}

void free_ast(AST *node)
{
    if (!node)
        return;
    switch (node->type)
    {
    case N_ASSIGN:
        free(node->assign.name);
        free_ast(node->assign.expr);
        break;
    case N_IF:
    case N_IFELSE:
        free_ast(node->ifn.cond);
        free_ast(node->ifn.thenb);
        if (node->type == N_IFELSE)
            free_ast(node->ifn.elseb);
        break;
    case N_WHILE:
        free_ast(node->whilen.cond);
        free_ast(node->whilen.body);
        break;
    case N_FOR:
        free_ast(node->forn.init);
        free_ast(node->forn.cond);
        free_ast(node->forn.upd);
        free_ast(node->forn.body);
        break;
    case N_BLOCK:
        for (int i = 0; i < node->block.count; i++)
            free_ast(node->block.stmts[i]);
        free(node->block.stmts);
        break;
    default:
        break;
    }
    free(node);
}

AST *new_var(char *name){
    AST *n = malloc(sizeof(AST));
    n->type = N_VAR;
    n->var_name = strdup(name);
    return n;
}

AST *new_binop(char op, AST *lhs, AST *rhs)
{
    AST **args = malloc(sizeof(AST *) * 2);
    args[0] = lhs;
    args[1] = rhs;
    return new_call(strdup((char[]){op, '\0'}), 2, args);
}

AST *new_unaryop(char op, AST *expr)
{
    AST **args = malloc(sizeof(AST *));
    args[0] = expr;
    return new_call(strdup((char[]){op, '\0'}), 1, args);
}

AST *new_print(AST *expr)
{
    AST **args = malloc(sizeof(AST *));
    args[0] = expr;
    return new_call("print", 1, args); // print 在 handle_function 中已有定义
}

AST *new_array_decl_init(char *name, AST *size, ASTList init_list) {
    AST *n = malloc(sizeof(AST));
    n->type = N_ARRAY_DECL;
    n->array_decl.name = strdup(name);
    n->array_decl.size = eval_ast(size);
    n->array_decl.init_list = malloc(sizeof(ASTList));
    *(n->array_decl.init_list) = init_list;
    return n;
}

AST *new_array_decl(char *name, AST *size) {
    AST *n = malloc(sizeof(AST));
    n->type = N_ARRAY_DECL;
    n->array_decl.name = strdup(name);
    n->array_decl.size = eval_ast(size);
    n->array_decl.init_list = NULL;
    return n;
}

AST *new_array_assign(char *name, AST *index, AST *value) {
    AST *n = malloc(sizeof(AST));
    n->type = N_ARRAY_ASSIGN;
    n->array_assign.name = strdup(name);
    n->array_assign.index = index;
    n->array_assign.value = value;
    return n;
}

AST *new_array_access(char *name, AST *index) {
    AST *n = malloc(sizeof(AST));
    n->type = N_ARRAY_ACCESS;
    n->array_access.name = strdup(name);
    n->array_access.index = index;
    return n;
}

void set_array(const char* name, int size) {
    for (int i = 0; i < var_count; ++i) {
        if (strcmp(symtab[i].name, name) == 0) {
            if (symtab[i].arr) free(symtab[i].arr);
            symtab[i].arr = calloc(size, sizeof(int));
            symtab[i].arr_size = size;
            return;
        }
    }
    symtab[var_count].name = strdup(name);
    symtab[var_count].arr = calloc(size, sizeof(int));
    symtab[var_count].arr_size = size;
    var_count++;
}

void set_array_elem(const char* name, int idx, int value) {
    for (int i = 0; i < var_count; ++i) {
        if (strcmp(symtab[i].name, name) == 0 && symtab[i].arr) {
            if (idx >= 0 && idx < symtab[i].arr_size)
                symtab[i].arr[idx] = value;
            else
                fprintf(stderr, "Array index out of bounds: %s[%d]\n", name, idx);
            return;
        }
    }
    fprintf(stderr, "Undefined array: %s\n", name);
}

int get_array_elem(const char* name, int idx) {
    for (int i = 0; i < var_count; ++i) {
        if (strcmp(symtab[i].name, name) == 0 && symtab[i].arr) {
            if (idx >= 0 && idx < symtab[i].arr_size)
                return symtab[i].arr[idx];
            else
                fprintf(stderr, "Array index out of bounds: %s[%d]\n", name, idx);
        }
    }
    fprintf(stderr, "Undefined array: %s\n", name);
    return 0;
}
