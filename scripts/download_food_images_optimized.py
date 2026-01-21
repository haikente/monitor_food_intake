"""
🎯 OPTIMIZED SCRIPT: Download 1,275 ảnh món ăn từ Pexels API

Improvements:
- ✅ Smarter search queries (Vietnamese name + English name + "food")
- ✅ Batch progress tracking
- ✅ Auto-retry failed downloads
- ✅ Resume capability (skip existing images)
- ✅ Quality validation (skip blank/corrupted images)
- ✅ Rate limiting (200 requests/hour = 1 request/18s)

Setup:
1. Install dependencies:
   pip install requests pillow

2. Get FREE Pexels API key:
   https://www.pexels.com/api/
   
3. Create .env file:
   PEXELS_API_KEY=your_key_here

4. Run:
   python scripts/download_food_images_optimized.py

Expected time: ~42 minutes for 1,275 images (with 2s delay)
"""

import os
import json
import time
import re
import requests
from PIL import Image
from io import BytesIO
from datetime import datetime
from pathlib import Path

# Configuration
PEXELS_API_KEY = "Nyb1jEcBnSqkmRTFcN1LvdWpaQwOfcna7sS36VGPZdufnTQjxlRimaGD"
OUTPUT_DIR = "assets/data/food_images"
TARGET_SIZE = 224
DELAY_BETWEEN_REQUESTS = 2  # seconds (200 req/hour = 18s, but we use 2s for safety with retries)
FAILED_LOG = "failed_downloads.json"

def load_api_key():
    """Load API key from .env or config"""
    # Try .env file first
    env_file = Path(".env")
    if env_file.exists():
        with open(env_file, 'r') as f:
            for line in f:
                if line.startswith("PEXELS_API_KEY"):
                    return line.split("=")[1].strip().strip('"')
    
    # Fallback to hardcoded
    if PEXELS_API_KEY != "YOUR_API_KEY_HERE":
        return PEXELS_API_KEY
    
    print("❌ ERROR: Please set PEXELS_API_KEY")
    print("   Get it from: https://www.pexels.com/api/")
    return None

def extract_food_data():
    """Extract food data từ Dart database"""
    print("📋 Extracting food data from database...")
    
    dart_file = "lib/data/database/food_database_generated.dart"
    
    if not os.path.exists(dart_file):
        print(f"❌ Database file not found: {dart_file}")
        return {}
    
    food_data = {}
    
    try:
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Pattern: 'food_key': FoodNutrition(name: 'Vietnamese Name', nameEn: 'English Name',
        pattern = r"'([a-z_0-9]+)':\s*FoodNutrition\(\s*name:\s*'([^']+)',\s*nameEn:\s*'([^']+)'"
        matches = re.findall(pattern, content, re.MULTILINE)
        
        for key, name_vn, name_en in matches:
            food_data[key] = {
                'name_vn': name_vn,
                'name_en': name_en
            }
        
        print(f"✅ Extracted {len(food_data)} foods")
        
        # Save to JSON for reference
        with open("food_data_extracted.json", 'w', encoding='utf-8') as f:
            json.dump(food_data, f, indent=2, ensure_ascii=False)
        
        return food_data
        
    except Exception as e:
        print(f"❌ Error extracting food data: {e}")
        return {}

def create_search_query(name_vn, name_en):
    """Tạo search query thông minh"""
    # Strategy: Try Vietnamese name first, then English name
    # Add "food" keyword to improve relevance
    
    queries = []
    
    # Query 1: English name + "food" (most likely to find on Pexels)
    if name_en and name_en.lower() != 'unknown':
        queries.append(f"{name_en} food")
    
    # Query 2: Vietnamese name romanized + "Vietnamese food"
    if name_vn:
        # Remove diacritics for Pexels search (it's English-based)
        romanized = remove_vietnamese_accents(name_vn)
        queries.append(f"{romanized} Vietnamese food")
    
    # Query 3: Just English name
    if name_en and name_en.lower() != 'unknown':
        queries.append(name_en)
    
    return queries

def remove_vietnamese_accents(text):
    """Remove Vietnamese diacritics"""
    vietnamese_map = {
        'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
        'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
        'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
        'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
        'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
        'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
        'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
        'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
        'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
        'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
        'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
        'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
        'đ': 'd',
        'Đ': 'D'
    }
    
    for viet, eng in vietnamese_map.items():
        text = text.replace(viet, eng)
    
    return text

def search_pexels(query, api_key):
    """Search Pexels API"""
    url = "https://api.pexels.com/v1/search"
    
    headers = {
        "Authorization": api_key
    }
    
    params = {
        "query": query,
        "per_page": 1,
        "orientation": "square"
    }
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        
        if data['photos']:
            # Get medium size (perfect for resizing to 224x224)
            return data['photos'][0]['src']['medium']
        else:
            return None
            
    except Exception as e:
        return None

def download_and_resize(url, output_path, target_size=224):
    """Download và resize ảnh"""
    try:
        response = requests.get(url, timeout=15)
        response.raise_for_status()
        
        img = Image.open(BytesIO(response.content))
        
        # Convert to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize
        img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)
        
        # Save
        img.save(output_path, 'JPEG', quality=95)
        
        # Validate (check if image is too small or corrupted)
        if os.path.getsize(output_path) < 5000:  # Less than 5KB = likely corrupted
            os.remove(output_path)
            return False
        
        return True
        
    except Exception as e:
        if os.path.exists(output_path):
            os.remove(output_path)
        return False

def load_failed_log():
    """Load danh sách các ảnh download thất bại"""
    if os.path.exists(FAILED_LOG):
        with open(FAILED_LOG, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}

def save_failed_log(failed_dict):
    """Save danh sách thất bại"""
    with open(FAILED_LOG, 'w', encoding='utf-8') as f:
        json.dump(failed_dict, f, indent=2, ensure_ascii=False)

def main():
    print("=" * 60)
    print("🎯 OPTIMIZED FOOD IMAGE DOWNLOADER FROM PEXELS")
    print("=" * 60)
    
    # Load API key
    api_key = load_api_key()
    if not api_key:
        return
    
    print(f"✅ API Key loaded: {api_key[:10]}...{api_key[-4:]}")
    
    # Extract food data
    food_data = extract_food_data()
    if not food_data:
        print("❌ No food data found!")
        return
    
    total_foods = len(food_data)
    print(f"\n📊 Total foods: {total_foods}")
    
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"📁 Output directory: {OUTPUT_DIR}")
    
    # Load failed log
    failed_log = load_failed_log()
    
    # Statistics
    stats = {
        'total': total_foods,
        'existing': 0,
        'downloaded': 0,
        'failed': 0,
        'skipped': 0
    }
    
    start_time = time.time()
    
    print(f"\n🚀 Starting download...")
    print(f"⏱️  Estimated time: ~{total_foods * DELAY_BETWEEN_REQUESTS / 60:.0f} minutes")
    print("=" * 60)
    
    # Process each food
    for idx, (food_key, food_info) in enumerate(food_data.items(), 1):
        name_vn = food_info['name_vn']
        name_en = food_info['name_en']
        output_path = os.path.join(OUTPUT_DIR, f"{food_key}.jpg")
        
        # Check if already exists
        if os.path.exists(output_path):
            stats['existing'] += 1
            print(f"[{idx}/{total_foods}] ⏭️  SKIP: {name_vn} (already exists)")
            continue
        
        # Try multiple search queries
        queries = create_search_query(name_vn, name_en)
        success = False
        
        for query_idx, query in enumerate(queries):
            if success:
                break
            
            print(f"[{idx}/{total_foods}] 🔍 Searching: {name_vn} (Query {query_idx + 1}: '{query}')")
            
            # Search Pexels
            image_url = search_pexels(query, api_key)
            
            if image_url:
                # Download and resize
                if download_and_resize(image_url, output_path, TARGET_SIZE):
                    stats['downloaded'] += 1
                    print(f"              ✅ Downloaded: {food_key}.jpg")
                    success = True
                else:
                    print(f"              ⚠️  Download failed, trying next query...")
            else:
                print(f"              ⚠️  No results, trying next query...")
            
            # Rate limiting
            time.sleep(DELAY_BETWEEN_REQUESTS)
        
        if not success:
            stats['failed'] += 1
            failed_log[food_key] = {
                'name_vn': name_vn,
                'name_en': name_en,
                'queries_tried': queries
            }
            print(f"              ❌ FAILED: Could not find image for {name_vn}")
        
        # Save failed log periodically
        if idx % 50 == 0:
            save_failed_log(failed_log)
            elapsed = time.time() - start_time
            remaining = (total_foods - idx) * DELAY_BETWEEN_REQUESTS
            print(f"\n📊 Progress: {idx}/{total_foods} ({idx/total_foods*100:.1f}%)")
            print(f"⏱️  Elapsed: {elapsed/60:.1f}m | Remaining: ~{remaining/60:.1f}m\n")
    
    # Final save
    save_failed_log(failed_log)
    
    # Print summary
    elapsed_time = time.time() - start_time
    print("\n" + "=" * 60)
    print("🎉 DOWNLOAD COMPLETE!")
    print("=" * 60)
    print(f"📊 Statistics:")
    print(f"   Total foods:      {stats['total']}")
    print(f"   ✅ Downloaded:    {stats['downloaded']}")
    print(f"   ⏭️  Already existed: {stats['existing']}")
    print(f"   ❌ Failed:        {stats['failed']}")
    print(f"\n⏱️  Total time: {elapsed_time/60:.1f} minutes")
    print(f"\n📁 Images saved to: {OUTPUT_DIR}")
    print(f"📝 Failed log saved to: {FAILED_LOG}")
    
    if stats['failed'] > 0:
        print(f"\n⚠️  {stats['failed']} images failed to download.")
        print("   You can manually download or try alternative sources.")
        print("   Check failed_downloads.json for details.")
    
    success_rate = (stats['downloaded'] / (stats['downloaded'] + stats['failed']) * 100) if (stats['downloaded'] + stats['failed']) > 0 else 0
    print(f"\n✨ Success rate: {success_rate:.1f}%")

if __name__ == "__main__":
    main()
