#include <stdio.h>
#include "ast.h"
extern int yyparse();
extern FILE *yyin;
extern void *root;
Variable symtab[MAX_VARS];
int var_count = 0;

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin)
    {
        perror("Failed to open input file");
        return 1;
    }

    int parse_result = yyparse();

    if (parse_result == 0) {
        // 语法分析成功
        exec_ast(root);
        free_ast(root);
    } else {
        // 语法分析失败，错误信息已由 yyerror 输出
        // 可以加一句，确保有输出
        fprintf(stderr, "Parsing failed due to syntax error(s).\n");
        fflush(stderr);
    }

    fclose(yyin);
    return 0;
}