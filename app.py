from flask import Flask, render_template, request, jsonify
import subprocess

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html")  # 渲染模板


@app.route("/compile", methods=["POST"])
def compile_and_run():
    code = request.json.get("code", "")

    # 保存为 main.c
    with open("app.txt", "w") as f:
        f.write(code)

    try:
        # 编译：flex、bison、gcc
        # 运行
        result = subprocess.run("./calc app.txt", input=b"",
                                capture_output=True, timeout=5)
        output = result.stdout.decode() + result.stderr.decode()

    except subprocess.CalledProcessError as e:
        output = f"编译出错：\n{e.stderr.decode() if e.stderr else str(e)}"
    except Exception as e:
        output = str(e)

    return jsonify({"output": output})


if __name__ == "__main__":
    app.run(debug=True)
