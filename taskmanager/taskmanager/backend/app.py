import os
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

tasks = []

@app.route("/api/tasks", methods=["GET"])
def get_tasks():
    return jsonify(tasks)

@app.route("/api/tasks", methods=["POST"])
def add_task():
    data = request.get_json()
    if not data or "task" not in data:
        return jsonify({"error": "Invalid data"}), 400
    task = {"task": data["task"]}
    tasks.append(task)
    print(tasks)
    return jsonify(task), 201

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))  # Cloud Run gives this
    app.run(host="0.0.0.0", port=port)
