"""
Script để extract food keys từ food_database_generated.dart

Usage:
    python scripts/extract_food_keys.py
"""

import re
import json

def extract_food_keys_from_dart():
    """Extract all food keys from Dart database file"""
    
    dart_file = "lib\\data\\database\\food_database_generated.dart"
    
    print(f"📂 Reading Dart file: {dart_file}...")
    
    try:
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find all food keys (pattern: 'key_name': FoodNutrition)
        pattern = r"'([a-z_0-9]+)':\s*FoodNutrition"
        matches = re.findall(pattern, content)
        
        food_keys = sorted(set(matches))
        
        print(f"✅ Found {len(food_keys)} food keys")
        
        # Save to JSON
        output_file = "food_keys.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(food_keys, f, indent=2, ensure_ascii=False)
        
        print(f"💾 Saved to: {output_file}")
        
        # Also create mapping with English names
        print("\n📋 Sample food keys:")
        for i, key in enumerate(food_keys[:10], 1):
            print(f"  {i}. {key}")
        print(f"  ... and {len(food_keys) - 10} more")
        
        return food_keys
        
    except FileNotFoundError:
        print(f"❌ File not found: {dart_file}")
        return []
    except Exception as e:
        print(f"❌ Error: {e}")
        return []

if __name__ == "__main__":
    print("=" * 60)
    print("🔍 Food Keys Extractor")
    print("=" * 60)
    print()
    
    keys = extract_food_keys_from_dart()
    
    if keys:
        print("\n" + "=" * 60)
        print("✅ SUCCESS!")
        print("=" * 60)
        print("\nNext steps:")
        print("1. Use food_keys.json for image download script")
        print("2. Create Vietnamese → English name mapping")
        print("3. Download images for each food")
    else:
        print("\n❌ FAILED to extract food keys")
