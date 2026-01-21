"""
Script download ảnh từ Pexels API (Alternative to Google Images)

Pexels API:
- Free tier: 200 requests/hour, 20,000/month
- Better quality images
- No rate limiting issues
- Easier to use than Google Images

Install:
    pip install requests pillow

Sign up:
    https://www.pexels.com/api/

Usage:
    python scripts/download_from_pexels.py
"""

import os
import json
import time
import requests
from PIL import Image
from io import BytesIO

def load_food_names():
    """Load danh sách món ăn từ database"""
    print("📋 Loading food names...")
    
    dart_file = "lib\\data\\database\\food_database_generated.dart"
    
    food_mapping = {}
    
    try:
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        import re
        pattern = r"'([a-z_0-9]+)':\s*FoodNutrition\(\s*name:\s*'([^']+)',\s*nameEn:\s*'([^']+)'"
        matches = re.findall(pattern, content, re.MULTILINE)
        
        for key, name_vn, name_en in matches:
            food_mapping[key] = {
                'name_vn': name_vn,
                'name_en': name_en
            }
        
        print(f"✅ Loaded {len(food_mapping)} foods")
        return food_mapping
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return {}

def search_pexels(query, api_key, per_page=1):
    """Tìm ảnh trên Pexels"""
    
    url = "https://api.pexels.com/v1/search"
    
    headers = {
        "Authorization": api_key
    }
    
    params = {
        "query": query,
        "per_page": per_page,
        "orientation": "square"  # Prefer square images
    }
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        
        if data['photos']:
            # Get medium size image (perfect for 224x224 resize)
            return data['photos'][0]['src']['medium']
        else:
            return None
            
    except Exception as e:
        print(f"⚠️ Search error: {e}")
        return None

def download_and_resize_image(url, output_path, target_size=224):
    """Download và resize ảnh"""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        img = Image.open(BytesIO(response.content))
        
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)
        img.save(output_path, 'JPEG', quality=95)
        
        return True
        
    except Exception as e:
        print(f"⚠️ Download error: {e}")
        return False

def main():
    print("=" * 70)
    print("🖼️ PEXELS FOOD IMAGE DOWNLOADER")
    print("=" * 70)
    print()
    
    # Get API key
    print("📝 Get your FREE API key at: https://www.pexels.com/api/")
    print()
    api_key = input("Enter your Pexels API key: ").strip()
    
    if not api_key:
        print("❌ API key required!")
        return
    
    # Load foods
    food_mapping = load_food_names()
    
    if not food_mapping:
        print("❌ Failed to load foods")
        return
    
    print(f"\n📊 Total foods: {len(food_mapping)}")
    print()
    
    # Batch options
    print("💡 Download options:")
    print("   1. All foods (1,273 images)")
    print("   2. Batch (specify range)")
    print("   3. Popular foods only (~100 images)")
    print()
    
    choice = input("Select option (1/2/3): ").strip()
    
    # Determine food list to process
    if choice == "2":
        start = int(input("Start index (1-1273): "))
        end = int(input("End index (1-1273): "))
        foods_to_process = dict(list(food_mapping.items())[start-1:end])
    elif choice == "3":
        # Popular Vietnamese foods (curated list)
        popular_keys = [
            'pho_bo', 'bun_cha', 'com_trang', 'banh_mi', 'goi_cuon',
            'bun_bo_hue', 'banh_xeo', 'cao_lau', 'mi_quang', 'hu_tieu',
            # Add more popular foods...
        ]
        foods_to_process = {k: v for k, v in food_mapping.items() if k in popular_keys}
    else:
        foods_to_process = food_mapping
    
    print(f"\n📦 Processing {len(foods_to_process)} foods")
    print()
    
    # Output directory
    output_dir = "assets\\food_images"
    os.makedirs(output_dir, exist_ok=True)
    
    # Statistics
    stats = {
        'success': 0,
        'failed': 0,
        'skipped': 0
    }
    
    # Save failed downloads for retry
    failed_foods = []
    
    # Process
    for i, (food_key, food_data) in enumerate(foods_to_process.items(), 1):
        output_path = os.path.join(output_dir, f"{food_key}.jpg")
        
        # Skip if exists
        if os.path.exists(output_path):
            print(f"⏭️ [{i}/{len(foods_to_process)}] Skipped: {food_key}")
            stats['skipped'] += 1
            continue
        
        # Search query
        query = f"vietnamese food {food_data['name_vn']} {food_data['name_en']}"
        
        print(f"🔍 [{i}/{len(foods_to_process)}] {food_data['name_vn']}")
        
        # Search
        image_url = search_pexels(query, api_key)
        
        if image_url:
            if download_and_resize_image(image_url, output_path):
                print(f"   ✅ Success")
                stats['success'] += 1
            else:
                print(f"   ❌ Failed to download")
                stats['failed'] += 1
                failed_foods.append((food_key, food_data))
        else:
            print(f"   ❌ No image found")
            stats['failed'] += 1
            failed_foods.append((food_key, food_data))
        
        # Rate limiting (200 requests/hour = 18 seconds between requests)
        time.sleep(2)
        
        # Progress every 50
        if i % 50 == 0:
            print()
            print(f"📊 Progress: {i}/{len(foods_to_process)} ({i/len(foods_to_process)*100:.1f}%)")
            print(f"   ✅ Success: {stats['success']}, ❌ Failed: {stats['failed']}, ⏭️ Skipped: {stats['skipped']}")
            print()
    
    # Save failed list
    if failed_foods:
        with open('failed_downloads.json', 'w', encoding='utf-8') as f:
            json.dump([
                {'key': k, 'name_vn': d['name_vn'], 'name_en': d['name_en']}
                for k, d in failed_foods
            ], f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Failed downloads saved to: failed_downloads.json")
    
    # Summary
    print()
    print("=" * 70)
    print("📊 FINAL SUMMARY")
    print("=" * 70)
    print(f"✅ Success:  {stats['success']}")
    print(f"❌ Failed:   {stats['failed']}")
    print(f"⏭️ Skipped:  {stats['skipped']}")
    print(f"📁 Total:    {stats['success'] + stats['skipped']} / {len(foods_to_process)}")
    print()
    
    coverage = (stats['success'] + stats['skipped']) / len(foods_to_process) * 100
    print(f"📈 Coverage: {coverage:.1f}%")
    
    if stats['failed'] > 0:
        print()
        print("💡 Tips for failed downloads:")
        print("   1. Re-run script to retry")
        print("   2. Try alternative search terms")
        print("   3. Manual download for remaining foods")
        print("   4. Use Unsplash or Pixabay as alternative")

if __name__ == "__main__":
    print("\n✨ PEXELS API ADVANTAGES:")
    print("=" * 70)
    print("✅ High quality images")
    print("✅ Free tier: 200 requests/hour, 20,000/month")
    print("✅ No rate limiting issues")
    print("✅ Stable API")
    print("✅ Commercial use allowed")
    print()
    print("⏱️ Estimated time:")
    print("   - 100 images: ~4 minutes")
    print("   - 500 images: ~17 minutes")
    print("   - 1,273 images: ~42 minutes")
    print()
    
    confirm = input("Start download? (yes/no): ").strip().lower()
    
    if confirm in ['yes', 'y']:
        print()
        main()
    else:
        print("\n❌ Cancelled")
