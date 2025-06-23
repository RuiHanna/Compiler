%{
#include "parser.tab.h"
#include <stdlib.h>
%}

%%
[0-9]+      { yylval = atoi(yytext); return NUMBER; }
[a-z]       { yylval = yytext[0]; return VAR; }
[=]         { return '='; }
[+\-*/()]   { return yytext[0]; }
[\n]+       { return EOL; }
[ \t\r]+    { /* 忽略空格 */ }
.           { printf("Unknown character: %s\n", yytext); }
%%

int yywrap() { return 1; }
