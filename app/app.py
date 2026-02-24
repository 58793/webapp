import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/")
def home():
    ver = os.getenv("APP_VERSION", "unknown")
    return f"Hello from my Flask app on ECS Fargate 🚀 (version={ver})\n"

@app.get("/health")
def health():
    return jsonify(
        status="ok",
        version=os.getenv("APP_VERSION", "unknown"),
        hostname=socket.gethostname(),
    )