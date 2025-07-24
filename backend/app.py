from flask import Flask, jsonify, request
import uuid
import time
from datetime import datetime

app = Flask(__name__)

# In-memory data stores
devices = [
    {
        "id": "1",
        "name": "samuel-macbook-pro.local",
        "ipAddress": "192.168.1.101",
        "macAddress": "A1:B2:C3:D4:E5:F6",
        "os": "macOS Sonoma",
        "isVulnerable": False
    },
    {
        "id": "2",
        "name": "living-room-appletv.local",
        "ipAddress": "192.168.1.105",
        "macAddress": "A2:B3:C4:D5:E6:F7",
        "os": "tvOS 17",
        "isVulnerable": True
    }
]
scans = {}

@app.route('/api/devices', methods=['GET'])
def get_devices():
    return jsonify(devices)

@app.route('/api/scan/start', methods=['POST'])
def start_scan():
    session_id = str(uuid.uuid4())
    scan = {
        "id": session_id,
        "target_range": request.json.get("target_range"),
        "scan_type": "network",
        "status": "in_progress",
        "created_at": datetime.utcnow().isoformat() + "Z",
        "completed_at": None,
        "progress": 0.0,
        "device_count": 0
    }
    scans[session_id] = scan
    return jsonify(scan)

@app.route('/api/scan/status/<session_id>', methods=['GET'])
def get_scan_status(session_id):
    scan = scans.get(session_id)
    if not scan:
        return jsonify({"error": "Scan not found"}), 404

    if scan["status"] == "in_progress":
        scan["progress"] += 0.1
        if scan["progress"] >= 1.0:
            scan["status"] = "completed"
            scan["completed_at"] = datetime.utcnow().isoformat() + "Z"
            scan["device_count"] = len(devices)

    return jsonify({
        "session_id": scan["id"],
        "status": scan["status"],
        "progress": scan["progress"],
        "current_task": "Scanning for devices...",
        "estimated_time_remaining": 10,
        "devices_found": int(scan["progress"] * len(devices)),
        "vulnerabilities_found": 1 if scan["progress"] >= 0.5 else 0
    })

if __name__ == '__main__':
    app.run(port=8000)
