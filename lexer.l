%{
#include "ast.h"
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* strdup(const char* s);  // strdup 非标准函数声明
int curr_lineno = 1;//当前行号
%}

%%
"//".*    {
    yylloc.first_line = curr_lineno;  // 注释起始行
    curr_lineno++;                      // 注释结束后换行
    yylloc.last_line = curr_lineno;    // 注释结束行
}
"/*"([^*]|\*+[^*/])*\*+"/"    {
    int start_line = curr_lineno;       // 块注释起始行
    for (int i = 0; yytext[i]; ++i) {
        if (yytext[i] == '\n') curr_lineno++;  // 统计块内换行
    }
    yylloc.first_line = start_line;     // 块注释起始行
    yylloc.last_line = curr_lineno;     // 块注释结束行
}

[\n]+    {
    yylloc.first_line = curr_lineno;    // 换行起始行
    curr_lineno++;                      // 行号递增
    yylloc.last_line = curr_lineno;     // 换行结束行
}

"if"    { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return IF; 
}
"else"  { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return ELSE; 
}
"while" { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return WHILE; 
}
"for"   { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return FOR; 
}

"int"    { 
    yylloc.first_line = yylloc.last_line = curr_lineno;  // 记录当前行号
    return INT_TYPE; 
}

"<"     { yylloc.first_line = yylloc.last_line = curr_lineno; return '<'; }  // 小于
">"     { yylloc.first_line = yylloc.last_line = curr_lineno; return '>'; }  // 大于
"<="    { yylloc.first_line = yylloc.last_line = curr_lineno; return LE; }   // 小于等于
">="    { yylloc.first_line = yylloc.last_line = curr_lineno; return GE; }   // 大于等于
"=="    { yylloc.first_line = yylloc.last_line = curr_lineno; return EQ; }   // 等于
"!="    { yylloc.first_line = yylloc.last_line = curr_lineno; return NEQ; }

[0-9]+   { 
    yylval.ival = atoi(yytext);
    yylloc.first_line = yylloc.last_line = curr_lineno;  // 记录当前行号
    return NUMBER; 
}
[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.name = strdup(yytext);
    yylloc.first_line = yylloc.last_line = curr_lineno;  // 记录当前行号
    return VAR;
}
[=] { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return '='; 
}
[+\-*/(),]   { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return yytext[0]; 
}

"{" { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return '{';  // 直接返回字符字面量作为token
}
"}" { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return '}';  // 直接返回字符字面量作为token
}

";"         { 
    yylloc.first_line = yylloc.last_line = curr_lineno; 
    return SEMICOLON; 
}  // 分号作为语句结束
[ \t\r]+    { /* 忽略空格 */ }
.           { 
    printf("Unknown character: %s\n", yytext);
    yylloc.first_line = yylloc.last_line = curr_lineno; 
}

%%

int yywrap() { return 1; }
