%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* strdup(const char* s);  // strdup 非标准函数声明
int curr_lineno = 1;//当前行号
%}

%%
"//".*        { curr_lineno++; }
"/*"([^*]|\*+[^*/])*\*+"/"    {
   for (int i = 0; yytext[i]; ++i)
        if (yytext[i] == '\n') curr_lineno++;
}

[\n]+       {curr_lineno ++;}

"int"           { return INT_TYPE; }

[0-9]+              { yylval.ival = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* {
                        yylval.name = strdup(yytext);
                        return VAR;
                     }
[=]         { return '='; }
[+\-*/(),]   { return yytext[0]; }

";"         { return SEMICOLON; }  // 分号作为语句结束
[ \t\r]+    { /* 忽略空格 */ }
.           { printf("Unknown character: %s\n", yytext); }

%%

int yywrap() { return 1; }
