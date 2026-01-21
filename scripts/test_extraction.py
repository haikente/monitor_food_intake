"""
Quick test script để verify extraction works
"""
import re

# Test extraction
dart_file = "lib/data/database/food_database_generated.dart"

with open(dart_file, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r"'([a-z_0-9]+)':\s*FoodNutrition\(\s*name:\s*'([^']+)',\s*nameEn:\s*'([^']+)'"
matches = re.findall(pattern, content, re.MULTILINE)

print(f"✅ Found {len(matches)} foods in database")
print("\n📋 First 10 foods:")
for key, name_vn, name_en in matches[:10]:
    print(f"   {key}: {name_vn} ({name_en})")

if len(matches) >= 1275:
    print(f"\n✅ READY! Database has {len(matches)} foods - enough for Image Anchor")
else:
    print(f"\n⚠️  WARNING: Only {len(matches)} foods found (expected 1,275)")
