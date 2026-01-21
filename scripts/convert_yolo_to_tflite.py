"""
YOLOv8 ONNX to TFLite Converter
Converts yolov8n.onnx to yolov8n.tflite for use in Flutter
"""

import sys
import os

def convert_yolo_to_tflite():
    """Convert YOLOv8 from .pt to .tflite using Ultralytics"""
    try:
        print("Converting YOLOv8 to TFLite...")
        print("=" * 50)
        
        # Check if ultralytics is installed
        try:
            from ultralytics import YOLO
        except ImportError:
            print("Ultralytics not found. Installing...")
            os.system(f"{sys.executable} -m pip install ultralytics")
            from ultralytics import YOLO
        
        # Load model
        model_path = "yolov8n.pt"
        if not os.path.exists(model_path):
            print(f"Model file not found: {model_path}")
            print("Downloading YOLOv8n...")
            model = YOLO("yolov8n.pt")  # Will auto-download
        else:
            print(f"Found model: {model_path}")
            model = YOLO(model_path)
        
        # Export to TFLite
        print("\nExporting to TFLite format...")
        model.export(format="tflite", imgsz=640)
        
        print("\nConversion successful!")
        print("=" * 50)
        print("\nOutput files:")
        
        # Find the output file
        saved_model_dir = "yolov8n_saved_model"
        if os.path.exists(saved_model_dir):
            for file in os.listdir(saved_model_dir):
                if file.endswith(".tflite"):
                    tflite_path = os.path.join(saved_model_dir, file)
                    print(f"   {tflite_path}")
                    
                    # Copy to assets/models/
                    assets_dir = "assets/models"
                    os.makedirs(assets_dir, exist_ok=True)
                    
                    import shutil
                    dest_path = os.path.join(assets_dir, "yolov8n.tflite")
                    shutil.copy(tflite_path, dest_path)
                    print(f"\nCopied to: {dest_path}")
        
        print("\nDone! You can now use yolov8n.tflite in your Flutter app.")
        print("\nNext steps:")
        print("   1. Make sure assets/models/yolov8n.tflite exists")
        print("   2. Update pubspec.yaml to include the asset")
        print("   3. Use YoloDetectionService in your code")
        
    except Exception as e:
        print(f"\nError: {e}")
        print("\nAlternative: Download pre-converted model:")
        print("   wget https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n_float32.tflite")
        sys.exit(1)

if __name__ == "__main__":
    convert_yolo_to_tflite()
