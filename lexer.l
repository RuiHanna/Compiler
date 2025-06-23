%{
#include "parser.tab.h"
%}

%%
[0-9]+      { yylval = atoi(yytext); return NUMBER; }
[+\-*/()]   { return yytext[0]; }
[\n]        { return EOL; }
[ \t]       { /* 忽略空格 */ }
.           { printf("Unknown Character: %s\n", yytext); }
%%

int yywrap() { return 1; }
