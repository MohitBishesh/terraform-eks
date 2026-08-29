"""Hello World HTTP microservice with a small animated UI."""

from flask import Flask, Response, render_template

app = Flask(__name__)


@app.get("/")
def home():
    return render_template("index.html")


@app.get("/api/hello")
def hello_plain():
    """Plain-text contract for the assignment / quick checks."""
    return Response("Hello World", status=200, mimetype="text/plain; charset=utf-8")


@app.get("/healthz")
def healthz():
    return Response("ok", status=200, mimetype="text/plain; charset=utf-8")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
