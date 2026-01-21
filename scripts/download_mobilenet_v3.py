"""
Script để download và convert MobileNetV3 model cho IMAGE-BASED Semantic Search

Requirements:
- Python 3.8+
- tensorflow 2.x
- tensorflow-hub

Install:
    pip install tensorflow tensorflow-hub

Usage:
    python scripts/download_mobilenet_v3.py
"""

import tensorflow as tf
import tensorflow_hub as hub
import os

def download_mobilenet_v3():
    print("🔽 Downloading MobileNetV3 from TensorFlow Hub...")
    
    # Load MobileNetV3 from TF Hub
    # This is the feature extraction model (without classification head)
    model_url = "https://tfhub.dev/google/imagenet/mobilenet_v3_large_100_224/feature_vector/5"
    
    try:
        # Download model
        model = hub.KerasLayer(model_url, trainable=False)
        print("✅ Model downloaded")
        
        # Create a simple model wrapper
        input_layer = tf.keras.Input(shape=(224, 224, 3))
        output_layer = model(input_layer)
        
        full_model = tf.keras.Model(inputs=input_layer, outputs=output_layer)
        
        print(f"📊 Model output shape: {full_model.output_shape}")
        print(f"   Expected: (None, 1280) - Feature vector size")
        
        # Convert to TFLite
        print("\n🔄 Converting to TFLite...")
        converter = tf.lite.TFLiteConverter.from_keras_model(full_model)
        
        # Optimization for mobile
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
        
        tflite_model = converter.convert()
        
        # Save model
        output_path = "../assets/models/mobilenet_v3_embedding.tflite"
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        model_size_mb = len(tflite_model) / (1024 * 1024)
        print(f"✅ Model saved to: {output_path}")
        print(f"📦 Model size: {model_size_mb:.2f} MB")
        
        # Verify model
        print("\n🔍 Verifying model...")
        interpreter = tf.lite.Interpreter(model_path=output_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"✅ Input shape: {input_details[0]['shape']}")
        print(f"✅ Output shape: {output_details[0]['shape']}")
        print(f"✅ Output dtype: {output_details[0]['dtype']}")
        
        expected_output_size = output_details[0]['shape'][-1]
        print(f"\n⚠️ IMPORTANT: Update Dart code to use embedding size: {expected_output_size}")
        print(f"   Current Dart code uses: 512")
        print(f"   MobileNetV3 Large outputs: {expected_output_size}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("🤖 MobileNetV3 Model Downloader")
    print("=" * 60)
    print()
    
    success = download_mobilenet_v3()
    
    if success:
        print("\n" + "=" * 60)
        print("✅ SUCCESS! Model ready to use")
        print("=" * 60)
        print("\nNext steps:")
        print("1. Update _embeddingSize in image_embedding_service.dart")
        print("2. Prepare food images dataset (1,275 images)")
        print("3. Run first-time initialization")
    else:
        print("\n" + "=" * 60)
        print("❌ FAILED! Check error messages above")
        print("=" * 60)
