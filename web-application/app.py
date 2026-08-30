"""Hello World HTTP microservice with UI and Prometheus metrics."""

from flask import Flask, Response, render_template
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

app = Flask(__name__)

HELLO_REQUESTS = Counter(
    "webapp_hello_requests_total",
    "Total Hello World responses served",
    ["path"],
)


@app.get("/")
def home():
    HELLO_REQUESTS.labels(path="/").inc()
    return render_template("index.html")


@app.get("/api/hello")
def hello_plain():
    """Plain-text contract for the assignment / quick checks."""
    HELLO_REQUESTS.labels(path="/api/hello").inc()
    return Response("Hello World", status=200, mimetype="text/plain; charset=utf-8")


@app.get("/healthz")
def healthz():
    return Response("ok", status=200, mimetype="text/plain; charset=utf-8")


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), status=200, mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
