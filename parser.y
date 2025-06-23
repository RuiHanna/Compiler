%{
#include <stdio.h>
#include <stdlib.h>
void yyerror(const char *s);
int yylex();
%}

%token NUMBER
%token EOL

%left '+' '-'
%left '*' '/'

%%

program:
    program expr EOL { printf("result = %d\n", $2); }
  | /* 空 */
  ;

expr:
    expr '+' expr { $$ = $1 + $3; }
  | expr '-' expr { $$ = $1 - $3; }
  | expr '*' expr { $$ = $1 * $3; }
  | expr '/' expr { $$ = $1 / $3; }
  | '(' expr ')'  { $$ = $2; }
  | NUMBER        { $$ = $1; }
  ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: %s\n", s);
}
