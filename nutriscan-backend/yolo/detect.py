#!/usr/bin/env python3
"""
NutriScan - YOLO Food Detection Script
Dipanggil oleh Express.js via child_process.spawn

Usage:
  python detect.py --image /path/to/image.jpg --model /path/to/best.pt

Output (JSON ke stdout):
  {"label": "sate_ayam", "confidence": 0.97}
"""

import sys
import json
import argparse

def detect(image_path: str, model_path: str) -> dict:
    try:
        from ultralytics import YOLO
        import os

        if not os.path.exists(image_path):
            return {"label": "unknown", "confidence": 0, "error": "Image not found"}

        if not os.path.exists(model_path):
            return {"label": "unknown", "confidence": 0, "error": "Model not found"}

        model   = YOLO(model_path)
        results = model(image_path, verbose=False)

        if not results or len(results) == 0:
            return {"label": "unknown", "confidence": 0}

        result = results[0]

        if result.probs is not None:
            # Classification model
            top1_idx    = result.probs.top1
            top1_conf   = float(result.probs.top1conf)
            label       = result.names[top1_idx]
        elif result.boxes is not None and len(result.boxes) > 0:
            # Detection model - ambil box dengan confidence tertinggi
            best_box  = max(result.boxes, key=lambda b: float(b.conf))
            cls_idx   = int(best_box.cls)
            label     = result.names[cls_idx]
            top1_conf = float(best_box.conf)
        else:
            return {"label": "unknown", "confidence": 0}

        return {
            "label":      label,
            "confidence": round(top1_conf, 4),
        }

    except ImportError:
        # Fallback jika ultralytics belum diinstall
        return {"label": "unknown", "confidence": 0, "error": "ultralytics not installed"}
    except Exception as e:
        return {"label": "unknown", "confidence": 0, "error": str(e)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--image', required=True, help='Path ke gambar')
    parser.add_argument('--model', required=True, help='Path ke model .pt')
    args = parser.parse_args()

    result = detect(args.image, args.model)
    # Print JSON ke stdout - dibaca oleh Express
    print(json.dumps(result))
    sys.exit(0)
