"""
Script để download ảnh món ăn Việt Nam từ internet

Requirements:
- Python 3.8+
- requests
- Pillow

Install:
    pip install requests Pillow

Usage:
    python scripts/download_food_images.py

Note: Đây là script MẪU. Bạn cần:
1. Có API key từ Unsplash/Pexels/Google Images
2. Hoặc tự chụp/thu thập ảnh
3. Hoặc sử dụng dataset có sẵn
"""

import os
import requests
from PIL import Image
from io import BytesIO
import json
import time

# Load food database keys
def load_food_keys():
    """Load danh sách food keys từ database"""
    print("📋 Loading food keys from database...")
    
    # TODO: Parse từ food_database_generated.dart
    # Hoặc tạo file JSON riêng với list food keys
    
    # Ví dụ một số món:
    sample_foods = [
        "com_trang",
        "pho_bo",
        "bun_cha",
        "banh_mi",
        "goi_cuon",
        # ... thêm 1,270 món nữa
    ]
    
    return sample_foods

def search_food_image(food_name, api_key=None):
    """
    Tìm ảnh món ăn từ Unsplash API
    
    Args:
        food_name: Tên món ăn (tiếng Anh)
        api_key: Unsplash API key
    
    Returns:
        URL ảnh hoặc None
    """
    if not api_key:
        print("⚠️ No API key provided. Please sign up at https://unsplash.com/developers")
        return None
    
    # Unsplash API endpoint
    url = "https://api.unsplash.com/search/photos"
    
    params = {
        "query": f"vietnamese food {food_name}",
        "per_page": 1,
        "orientation": "landscape",
    }
    
    headers = {
        "Authorization": f"Client-ID {api_key}"
    }
    
    try:
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()
        
        data = response.json()
        
        if data["results"]:
            return data["results"][0]["urls"]["regular"]
        else:
            return None
            
    except Exception as e:
        print(f"❌ Error searching {food_name}: {e}")
        return None

def download_image(url, output_path):
    """Download và resize ảnh"""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        # Load image
        img = Image.open(BytesIO(response.content))
        
        # Resize to 224x224 (model input size)
        img = img.resize((224, 224), Image.Resampling.LANCZOS)
        
        # Convert to RGB (remove alpha channel if exists)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Save
        img.save(output_path, 'JPEG', quality=95)
        
        return True
        
    except Exception as e:
        print(f"❌ Error downloading: {e}")
        return False

def main():
    print("=" * 60)
    print("🖼️ Food Images Downloader")
    print("=" * 60)
    print()
    
    # API key (cần đăng ký tại unsplash.com/developers)
    API_KEY = input("Enter your Unsplash API key (or press Enter to skip): ").strip()
    
    if not API_KEY:
        print("\n⚠️ No API key provided.")
        print("\nAlternative options:")
        print("1. Sign up at: https://unsplash.com/developers")
        print("2. Use Pexels: https://www.pexels.com/api/")
        print("3. Manual collection (recommended for Vietnamese foods)")
        print("4. Use existing dataset")
        print("\n💡 For Vietnamese foods, manual collection gives best results!")
        return
    
    # Create output directory
    output_dir = "../assets/food_images"
    os.makedirs(output_dir, exist_ok=True)
    
    # Load food keys
    food_keys = load_food_keys()
    
    print(f"\n📊 Total foods to download: {len(food_keys)}")
    print(f"📁 Output directory: {output_dir}")
    print()
    
    # Statistics
    success_count = 0
    failed_count = 0
    skipped_count = 0
    
    for i, food_key in enumerate(food_keys, 1):
        output_path = os.path.join(output_dir, f"{food_key}.jpg")
        
        # Skip if already exists
        if os.path.exists(output_path):
            print(f"⏭️ [{i}/{len(food_keys)}] Skipped: {food_key} (already exists)")
            skipped_count += 1
            continue
        
        print(f"🔍 [{i}/{len(food_keys)}] Searching: {food_key}...", end=" ")
        
        # Convert key to name (e.g., "com_trang" → "steamed rice")
        # TODO: Add translation mapping
        food_name_en = food_key.replace("_", " ")
        
        # Search image
        image_url = search_food_image(food_name_en, API_KEY)
        
        if image_url:
            # Download
            if download_image(image_url, output_path):
                print(f"✅ Success")
                success_count += 1
            else:
                print(f"❌ Failed to download")
                failed_count += 1
        else:
            print(f"❌ No image found")
            failed_count += 1
        
        # Rate limiting (Unsplash allows 50 requests/hour for free tier)
        time.sleep(1)
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 SUMMARY")
    print("=" * 60)
    print(f"✅ Success: {success_count}")
    print(f"❌ Failed: {failed_count}")
    print(f"⏭️ Skipped: {skipped_count}")
    print(f"📁 Total images: {success_count + skipped_count} / {len(food_keys)}")
    
    if failed_count > 0:
        print("\n⚠️ Some images failed to download.")
        print("💡 Consider manual collection for missing foods")

if __name__ == "__main__":
    main()
