# Compiler

语言：C + Python (可视化)

运行：

- 编译parser.y

```bash
win_bison parser.y -d -o parser.tab.c
```

- 编译lexer.l

```bash
win_flex --outfile=lex.yy.c lexer.l
```

- 编译main.c

```bash
gcc -o calc main.c lex.yy.c parser.tab.c
```

- 可视化运行

```bash
# create your own virtual environment
pip install -r requirements.txt
python app.py
```

打开浏览器，输入`localhost:5000`
