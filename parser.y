%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

void yyerror(const char *s);
int yylex();

int sym[26]; // 用于变量 a-z
%}

%token VAR
%token NUMBER
%token EOL

%left '+' '-'
%left '*' '/'
%right UMINUS   // 一元减号优先级高于乘除加减

%%

program:
    program stmt EOL     { printf("Result = %d\n", $2); }
  | program EOL          { /* 支持空行 */ }
  | /* 空程序 */        
  ;

stmt:
    expr                { $$ = $1; }
  | VAR '=' expr        { sym[$1 - 'a'] = $3; $$ = $3; }
  ;

expr:
    expr '+' expr        { $$ = $1 + $3; }
  | expr '-' expr        { $$ = $1 - $3; }
  | expr '*' expr        { $$ = $1 * $3; }
  | expr '/' expr        { 
        if ($3 == 0) {
            yyerror("Division by zero");
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
  | '-' expr %prec UMINUS { $$ = -$2; }
  | '(' expr ')'         { $$ = $2; }
  | NUMBER               { $$ = $1; }
  | VAR                 { $$ = sym[$1 - 'a']; }
  ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: %s\n", s);
}
