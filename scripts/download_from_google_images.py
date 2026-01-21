"""
Script để tự động download ảnh món ăn từ Google Images

Requirements:
- Python 3.8+
- google-images-download hoặc selenium
- Pillow

Install:
    pip install google-images-download pillow
    pip install selenium webdriver-manager
    
Usage:
    python scripts/download_from_google_images.py
"""

import os
import json
import time
from pathlib import Path
from PIL import Image
from io import BytesIO
import requests

# Selenium for Google Images
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

def setup_driver():
    """Setup Chrome WebDriver với headless mode"""
    print("🔧 Setting up Chrome WebDriver...")
    
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1920,1080")
    
    # User agent để tránh bị block
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)
    
    return driver

def load_food_names():
    """Load danh sách món ăn từ database"""
    print("📋 Loading food names...")
    
    # Load từ food_database_generated.dart
    dart_file = "lib\\data\\database\\food_database_generated.dart"
    
    food_mapping = {}
    
    try:
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract food key + Vietnamese name + English name
        import re
        
        # Pattern để match: 'key': FoodNutrition(name: 'Tên VN', nameEn: 'English Name',
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
        print(f"❌ Error loading food names: {e}")
        return {}

def search_google_images(driver, query, max_results=1):
    """Tìm ảnh trên Google Images"""
    
    # Encode query
    search_url = f"https://www.google.com/search?q={query}&tbm=isch"
    
    try:
        driver.get(search_url)
        time.sleep(2)  # Wait for page load
        
        # Scroll để load ảnh
        driver.execute_script("window.scrollTo(0, 1000);")
        time.sleep(1)
        
        # Tìm ảnh thumbnails
        images = driver.find_elements(By.CSS_SELECTOR, "img.rg_i")
        
        if not images:
            return None
        
        # Click vào ảnh đầu tiên
        images[0].click()
        time.sleep(1)
        
        # Lấy ảnh full size
        full_images = driver.find_elements(By.CSS_SELECTOR, "img.n3VNCb")
        
        for img in full_images:
            src = img.get_attribute('src')
            if src and src.startswith('http'):
                return src
        
        return None
        
    except Exception as e:
        print(f"⚠️ Search error: {e}")
        return None

def download_image(url, output_path, target_size=224):
    """Download và resize ảnh"""
    try:
        # Download
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        # Open image
        img = Image.open(BytesIO(response.content))
        
        # Convert to RGB
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize to square (224x224)
        img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)
        
        # Save
        img.save(output_path, 'JPEG', quality=95)
        
        return True
        
    except Exception as e:
        print(f"⚠️ Download error: {e}")
        return False

def main():
    print("=" * 70)
    print("🖼️ GOOGLE IMAGES FOOD DOWNLOADER")
    print("=" * 70)
    print()
    
    # Load food names
    food_mapping = load_food_names()
    
    if not food_mapping:
        print("❌ Failed to load food names")
        return
    
    print(f"📊 Total foods: {len(food_mapping)}")
    print()
    
    # Output directory
    output_dir = "assets\\food_images"
    os.makedirs(output_dir, exist_ok=True)
    
    # Setup WebDriver
    driver = setup_driver()
    print("✅ Chrome WebDriver ready")
    print()
    
    # Statistics
    stats = {
        'success': 0,
        'failed': 0,
        'skipped': 0
    }
    
    # Process each food
    try:
        for i, (food_key, food_data) in enumerate(food_mapping.items(), 1):
            output_path = os.path.join(output_dir, f"{food_key}.jpg")
            
            # Skip if exists
            if os.path.exists(output_path):
                print(f"⏭️ [{i}/{len(food_mapping)}] Skipped: {food_key} (exists)")
                stats['skipped'] += 1
                continue
            
            # Search query: Vietnamese + English name for better results
            query = f"vietnamese food {food_data['name_vn']} {food_data['name_en']}"
            
            print(f"🔍 [{i}/{len(food_mapping)}] Searching: {food_data['name_vn']}")
            print(f"   Query: {query}")
            
            # Search
            image_url = search_google_images(driver, query)
            
            if image_url:
                # Download
                if download_image(image_url, output_path):
                    print(f"   ✅ Downloaded: {food_key}.jpg")
                    stats['success'] += 1
                else:
                    print(f"   ❌ Failed to download")
                    stats['failed'] += 1
            else:
                print(f"   ❌ No image found")
                stats['failed'] += 1
            
            # Rate limiting
            time.sleep(2)  # 2 giây giữa mỗi search
            
            # Progress report every 50 foods
            if i % 50 == 0:
                print()
                print(f"📊 Progress: {i}/{len(food_mapping)} ({i/len(food_mapping)*100:.1f}%)")
                print(f"   Success: {stats['success']}, Failed: {stats['failed']}, Skipped: {stats['skipped']}")
                print()
    
    finally:
        # Cleanup
        driver.quit()
        print("\n🔧 WebDriver closed")
    
    # Final summary
    print()
    print("=" * 70)
    print("📊 FINAL SUMMARY")
    print("=" * 70)
    print(f"✅ Success:  {stats['success']}")
    print(f"❌ Failed:   {stats['failed']}")
    print(f"⏭️ Skipped:  {stats['skipped']}")
    print(f"📁 Total:    {stats['success'] + stats['skipped']} / {len(food_mapping)}")
    print()
    
    coverage = (stats['success'] + stats['skipped']) / len(food_mapping) * 100
    print(f"📈 Coverage: {coverage:.1f}%")
    
    if stats['failed'] > 0:
        print()
        print("⚠️ Some images failed to download.")
        print("💡 Tips:")
        print("   1. Re-run script to retry failed downloads")
        print("   2. Manually download missing images")
        print("   3. Use alternative search queries")
        print("   4. Try different image sources")

if __name__ == "__main__":
    print("\n⚠️ IMPORTANT NOTES:")
    print("=" * 70)
    print("1. This script uses Selenium WebDriver (automated browser)")
    print("2. Download speed: ~30 seconds per image = ~11 hours for 1,273 images")
    print("3. Google may rate-limit or block automated requests")
    print("4. Consider running in batches (100-200 images at a time)")
    print("5. Manual collection may be faster and more accurate")
    print()
    
    confirm = input("Continue? (yes/no): ").strip().lower()
    
    if confirm in ['yes', 'y']:
        print()
        main()
    else:
        print("\n❌ Cancelled by user")
