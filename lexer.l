%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* strdup(const char* s);  // strdup 非标准函数声明
%}

%%
"int"           { return INT_TYPE; }
[0-9]+              { yylval.ival = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* {
                        yylval.name = strdup(yytext);
                        return VAR;
                     }
[=]         { return '='; }
[+\-*/(),]   { return yytext[0]; }
";"         { return SEMICOLON; }  // 分号作为语句结束
[ \t\r\n]+    { /* 忽略空格 */ }
.           { printf("Unknown character: %s\n", yytext); }
"//".*        { /* 忽略单行注释 */ }
"/*"([^*]|\*+[^*/])*\*+"/"    { /* 忽略多行注释 */ }

%%

int yywrap() { return 1; }
