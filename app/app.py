from flask import Flask
app = Flask(__name__)

@app.get("/health")
def health():
    return "ok", 200

@app.get("/")
def home():
    return "Hello from my Flask app on ECS Fargate 🚀", 200