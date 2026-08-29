"""Minimal Hello World HTTP microservice for the DevOps take-home."""

from flask import Flask

app = Flask(__name__)


@app.get("/")
def hello():
    return "Hello World", 200, {"Content-Type": "text/plain; charset=utf-8"}


@app.get("/healthz")
def healthz():
    return "ok", 200, {"Content-Type": "text/plain; charset=utf-8"}


if __name__ == "__main__":
    # Bind all interfaces so the container port mapping works.
    app.run(host="0.0.0.0", port=8080)
