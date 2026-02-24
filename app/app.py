import os
from flask import Flask

app = Flask(__name__)

@app.get("/")
def home():
    ver = os.getenv("APP_VERSION", "unknown")
    return f"Hello from my Flask app on ECS Fargate 🚀 (version={ver})\n"

@app.get("/health")
def health():
    return "ok\n"