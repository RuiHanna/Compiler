# Compiler

语言：C + Python (可视化)

运行：

- 编译parser.y

```bash
win_bison -d parser.y
```

- 编译lexer.l

```bash
win_flex lexer.l
```

- 编译main.c

```bash
gcc -o calc main.c parser.tab.c lex.yy.c ast.c -lm
```

- 可视化运行

```bash
# create your own virtual environment
# pip install before you first run our code
pip install -r requirements.txt
python app.py
```

打开浏览器，输入`localhost:5000`
