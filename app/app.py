from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "cloudlaunch"})

@app.route('/')
def home():
    return jsonify({"message": "CloudLaunch API is running"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)

