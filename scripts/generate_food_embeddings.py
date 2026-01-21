"""
🎯 Generate 1280D embeddings cho tất cả food images
Using: MobileNetV3 Large (TFLite)

Input: assets/data/food_images/*.jpg
Output: food_embeddings.json

Estimated time: 10-15 minutes for 1,100 images
"""

import os
import json
import time
import numpy as np
from PIL import Image

# Try tflite_runtime first (lighter), fallback to tensorflow
try:
    import tflite_runtime.interpreter as tflite
    print("✅ Using tflite_runtime")
except ImportError:
    try:
        import tensorflow.lite as tflite
        print("✅ Using tensorflow.lite")
    except ImportError:
        print("❌ ERROR: Please install one of:")
        print("   pip install tflite-runtime")
        print("   pip install tensorflow")
        exit(1)

def load_model(model_path):
    """Load TFLite model"""
    print(f"🤖 Loading model from: {model_path}")
    interpreter = tflite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    
    # Get input/output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"   Input shape: {input_details[0]['shape']}")
    print(f"   Output shape: {output_details[0]['shape']}")
    
    return interpreter

def preprocess_image(image_path, target_size=224):
    """Load và preprocess ảnh cho MobileNetV3"""
    try:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)
        
        # Convert to numpy array [0, 1]
        img_array = np.array(img, dtype=np.float32) / 255.0
        
        # Add batch dimension: (1, 224, 224, 3)
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
        
    except Exception as e:
        print(f"⚠️  Error loading image {image_path}: {e}")
        return None

def generate_embedding(interpreter, image_array):
    """Generate 1280D embedding với TFLite"""
    try:
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        # Set input tensor
        interpreter.set_tensor(input_details[0]['index'], image_array)
        
        # Run inference
        interpreter.invoke()
        
        # Get output tensor (1280D vector)
        embedding = interpreter.get_tensor(output_details[0]['index'])[0]
        
        # L2 normalize (unit vector)
        norm = np.linalg.norm(embedding)
        if norm > 0:
            embedding = embedding / norm
        
        return embedding.tolist()
        
    except Exception as e:
        print(f"⚠️  Error generating embedding: {e}")
        return None

def main():
    print("=" * 70)
    print("🎯 GENERATE FOOD EMBEDDINGS WITH MOBILENETV3")
    print("=" * 70)
    
    # Configuration
    model_path = "assets/models/mobilenet_v3_embedding.tflite"
    images_dir = "assets/data/food_images"
    output_file = "food_embeddings.json"
    
    # Validate paths
    if not os.path.exists(model_path):
        print(f"\n❌ Model not found: {model_path}")
        print("   Please run: python scripts/download_mobilenet_v3_fixed.py")
        return
    
    if not os.path.exists(images_dir):
        print(f"\n❌ Images directory not found: {images_dir}")
        print("   Please download images first")
        return
    
    # Load model
    print("\n📦 Loading MobileNetV3 model...")
    try:
        interpreter = load_model(model_path)
        print("✅ Model loaded successfully!")
    except Exception as e:
        print(f"❌ Failed to load model: {e}")
        return
    
    # Get all image files
    print(f"\n📁 Scanning images directory: {images_dir}")
    image_files = [f for f in os.listdir(images_dir) if f.endswith(('.jpg', '.jpeg', '.png'))]
    total_images = len(image_files)
    
    if total_images == 0:
        print("❌ No images found!")
        return
    
    print(f"✅ Found {total_images} images")
    print(f"⏱️  Estimated time: ~{total_images * 0.5 / 60:.1f} minutes")
    
    # Ask for confirmation
    print("\n" + "=" * 70)
    response = input(f"Start generating {total_images} embeddings? [Y/n]: ")
    if response.lower() == 'n':
        print("❌ Cancelled by user")
        return
    
    print("=" * 70)
    print("\n🚀 Starting embeddings generation...\n")
    
    # Process images
    embeddings = {}
    failed = []
    start_time = time.time()
    
    for idx, filename in enumerate(image_files, 1):
        food_key = filename.rsplit('.', 1)[0]  # Remove extension
        image_path = os.path.join(images_dir, filename)
        
        # Preprocess
        image_array = preprocess_image(image_path)
        if image_array is None:
            failed.append(food_key)
            continue
        
        # Generate embedding
        embedding = generate_embedding(interpreter, image_array)
        if embedding is None:
            failed.append(food_key)
            continue
        
        # Validate embedding size
        if len(embedding) != 1280:
            print(f"⚠️  [{idx}/{total_images}] {food_key}: Wrong size {len(embedding)}D (expected 1280D)")
            failed.append(food_key)
            continue
        
        # Save
        embeddings[food_key] = embedding
        
        # Progress update
        if idx % 50 == 0 or idx == total_images:
            elapsed = time.time() - start_time
            avg_time = elapsed / idx
            remaining = (total_images - idx) * avg_time
            success_rate = len(embeddings) / idx * 100
            
            print(f"[{idx}/{total_images}] Progress: {idx/total_images*100:.1f}%")
            print(f"   ✅ Success: {len(embeddings)} ({success_rate:.1f}%)")
            print(f"   ❌ Failed: {len(failed)}")
            print(f"   ⏱️  Elapsed: {elapsed/60:.1f}m | Remaining: ~{remaining/60:.1f}m")
            print()
    
    # Save embeddings to JSON
    print("💾 Saving embeddings to JSON...")
    with open(output_file, 'w') as f:
        json.dump(embeddings, f, indent=2)
    
    # Calculate file size
    file_size_mb = os.path.getsize(output_file) / 1024 / 1024
    
    # Save failed list
    if failed:
        failed_file = "failed_embeddings.json"
        with open(failed_file, 'w') as f:
            json.dump(failed, f, indent=2)
        print(f"⚠️  Failed list saved to: {failed_file}")
    
    # Final statistics
    elapsed_time = time.time() - start_time
    success_rate = len(embeddings) / total_images * 100
    
    print("\n" + "=" * 70)
    print("🎉 EMBEDDINGS GENERATION COMPLETE!")
    print("=" * 70)
    print(f"\n📊 Statistics:")
    print(f"   Total images:     {total_images}")
    print(f"   ✅ Success:       {len(embeddings)} ({success_rate:.1f}%)")
    print(f"   ❌ Failed:        {len(failed)} ({len(failed)/total_images*100:.1f}%)")
    print(f"   📊 Embedding dim: 1280D per image")
    print(f"   💾 File size:     {file_size_mb:.2f} MB")
    print(f"   ⏱️  Total time:    {elapsed_time/60:.1f} minutes")
    print(f"   ⚡ Avg speed:     {elapsed_time/total_images:.2f}s per image")
    
    print(f"\n📁 Output file: {output_file}")
    
    if failed:
        print(f"\n⚠️  {len(failed)} images failed to process")
        print(f"   Check: failed_embeddings.json")
    
    print("\n✅ Ready for next step!")
    print("   Next: python scripts/integrate_embeddings_to_database.py")
    print("=" * 70)

if __name__ == "__main__":
    main()
