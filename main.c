#include <stdio.h>
extern int yyparse();

int main()
{
    printf("输入表达式，每行一条（Ctrl+D/Ctrl+Z 结束）：\n");
    yyparse();
    return 0;
}
