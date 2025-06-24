#include <stdio.h>
extern int yyparse();
extern FILE *yyin;

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

    yyparse();

    fclose(yyin);
    return 0;
}
