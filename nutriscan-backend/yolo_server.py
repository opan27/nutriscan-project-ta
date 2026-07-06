from flask import Flask, request, jsonify
from ultralytics import YOLO
import os

app = Flask(__name__)

# LOAD MODEL SEKALI SAJA
MODEL_PATH = "./yolo/best.pt"

print("Loading YOLO model...")
model = YOLO(MODEL_PATH)
print("YOLO model loaded!")

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
        results = model(image_path, verbose=False)

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

            return jsonify({
                "label": label,
                "confidence": round(top1_conf, 4)
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
                "detections": detections
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
        port=5001,
        debug=True
    )