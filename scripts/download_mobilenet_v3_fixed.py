"""
🤖 Download MobileNetV3 Large model từ TensorFlow Hub
Output: 1280D feature vector model (TFLite format)
Model size: ~5-10MB
"""

import tensorflow as tf
import tensorflow_hub as hub
import numpy as np
import os

def main():
    print("=" * 60)
    print("🤖 DOWNLOAD MOBILENET V3 LARGE")
    print("=" * 60)
    
    # Model URL
    model_url = "https://tfhub.dev/google/imagenet/mobilenet_v3_large_100_224/feature_vector/5"
    
    print(f"\n📥 Downloading from: {model_url}")
    print("⏱️  This may take 2-5 minutes...")
    
    try:
        # Load model
        model = hub.load(model_url)
        print("✅ Model downloaded successfully!")
        
        # Test model
        print("\n🧪 Testing model...")
        test_input = np.random.rand(1, 224, 224, 3).astype(np.float32)
        output = model(test_input)
        print(f"✅ Input shape: {test_input.shape}")
        print(f"✅ Output shape: {output.shape}")  # Should be (1, 1280)
        
        if output.shape[1] != 1280:
            print(f"⚠️  WARNING: Expected 1280D output, got {output.shape[1]}D")
        
        # Convert to TFLite
        print("\n📦 Converting to TFLite format...")
        
        # Create concrete function
        @tf.function(input_signature=[tf.TensorSpec(shape=[1, 224, 224, 3], dtype=tf.float32)])
        def model_fn(x):
            return model(x)
        
        concrete_func = model_fn.get_concrete_function()
        
        # Convert
        converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        # Create directory if not exists
        output_dir = "assets/models"
        os.makedirs(output_dir, exist_ok=True)
        
        # Save
        output_path = os.path.join(output_dir, "mobilenet_v3_embedding.tflite")
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        # Get file size
        size_mb = os.path.getsize(output_path) / 1024 / 1024
        
        print("\n" + "=" * 60)
        print("🎉 MODEL DOWNLOAD COMPLETE!")
        print("=" * 60)
        print(f"✅ Model saved to: {output_path}")
        print(f"📊 File size: {size_mb:.2f} MB")
        print(f"📊 Output dimension: 1280D")
        print(f"\n✅ Ready for embeddings generation!")
        print(f"   Next: python scripts/generate_food_embeddings.py")
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        print("\n💡 Troubleshooting:")
        print("   1. Check internet connection")
        print("   2. Install: pip install tensorflow tensorflow-hub")
        print("   3. Try again")
        return

if __name__ == "__main__":
    main()
