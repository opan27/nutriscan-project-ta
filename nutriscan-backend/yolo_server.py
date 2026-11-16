from flask import Flask, request, jsonify
from ultralytics import YOLO
import os
import time
import numpy as np

app = Flask(__name__)

# LOAD MODEL SEKALI SAJA
MODEL_PATH = "./yolo/best.pt"

print("Loading YOLO model...")
model = YOLO(MODEL_PATH)
print("YOLO model loaded!")

# Parameter inferensi (sama dengan default Ultralytics, ditulis eksplisit untuk dokumentasi)
CONF_THRESHOLD = float(os.environ.get("CONF_THRESHOLD", 0.25))
IOU_THRESHOLD = float(os.environ.get("IOU_THRESHOLD", 0.7))
IMG_SIZE = int(os.environ.get("IMG_SIZE", 640))

# Warm-up: inferensi pertama lambat (inisialisasi PyTorch), jalankan sekali saat start
_t = time.time()
model(np.zeros((IMG_SIZE, IMG_SIZE, 3), dtype=np.uint8), imgsz=IMG_SIZE, verbose=False)
print(f"YOLO warm-up selesai ({(time.time() - _t) * 1000:.0f} ms)")

# ─── Health Check (untuk Docker healthcheck) ─────────────────────────────────
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "model": "loaded"}), 200

@app.route("/detect", methods=["POST"])
def detect():

    try:

        data = request.get_json()

        image_path = data.get("image")

        if not image_path:
            return jsonify({
                "label": "unknown",
                "confidence": 0,
                "error": "Image path required"
            }), 400

        if not os.path.exists(image_path):
            return jsonify({
                "label": "unknown",
                "confidence": 0,
                "error": "Image not found"
            }), 404

        # YOLO inference
        t0 = time.time()
        results = model(image_path, imgsz=IMG_SIZE, conf=CONF_THRESHOLD,
                        iou=IOU_THRESHOLD, verbose=False)
        infer_ms = (time.time() - t0) * 1000
        print(f"[detect] inferensi {infer_ms:.0f} ms | {os.path.basename(image_path)}", flush=True)

        if not results or len(results) == 0:
            return jsonify({
                "label": "unknown",
                "confidence": 0
            })

        result = results[0]

        # CLASSIFICATION MODEL
        if result.probs is not None:

            top1_idx = result.probs.top1
            top1_conf = float(result.probs.top1conf)

            label = result.names[top1_idx]

            # Format sama dengan model deteksi agar backend bisa membaca `detections`
            detections = []
            if top1_conf >= CONF_THRESHOLD:
                detections.append({"label": label, "confidence": round(top1_conf, 4)})

            return jsonify({
                "label": label,
                "confidence": round(top1_conf, 4),
                "total_objects": len(detections),
                "detections": detections,
                "inference_ms": round(infer_ms, 1)
            })

        # DETECTION MODEL
        elif result.boxes is not None and len(result.boxes) > 0:

            detections = []

            for box in result.boxes:
                cls_idx = int(box.cls[0])
                confidence = float(box.conf[0])

                detections.append({
                    "label": result.names[cls_idx],
                    "confidence": round(confidence, 4)
                })

            return jsonify({
                "total_objects": len(detections),
                "detections": detections,
                "inference_ms": round(infer_ms, 1)
            })

        else:
            return jsonify({
                "label": "unknown",
                "confidence": 0
            })

    except Exception as e:
        return jsonify({
            "label": "unknown",
            "confidence": 0,
            "error": str(e)
        }), 500


if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", 5001)),
        debug=os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    )