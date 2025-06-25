from flask import Flask, render_template, request, jsonify
import subprocess
import os

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html")  # 渲染模板


@app.route("/compile", methods=["POST"])
def compile_and_run():
    code = request.json.get("code", "")

    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    calc_path = os.path.join(BASE_DIR, "calc.exe")
    app_txt_path = os.path.join(BASE_DIR, "app.txt")

    with open(app_txt_path, "w", encoding="utf-8") as f:
        f.write(code)

    print("calc_path exists:", os.path.exists(calc_path))
    print("app_txt_path exists:", os.path.exists(app_txt_path))

    try:
        result = subprocess.run([calc_path, app_txt_path],
                                capture_output=True, timeout=5)
        print("returncode:", result.returncode)
        print("stdout:", repr(result.stdout))
        print("stderr:", repr(result.stderr))
        output = result.stdout.decode(
            errors="replace") + result.stderr.decode(errors="replace")
        print("====output====")
        print(output)
        print("=============")
    except subprocess.CalledProcessError as e:
        output = f"编译出错：\n{e.stderr.decode() if e.stderr else str(e)}"
    except Exception as e:
        output = str(e) + "\n" + repr(e)

    return jsonify({"output": output})


if __name__ == "__main__":
    app.run(debug=True)
