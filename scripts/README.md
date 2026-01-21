# 🛠️ SCRIPTS FOLDER - IMAGE-BASED SEMANTIC SEARCH

## 📋 AVAILABLE SCRIPTS

### 1. `extract_food_keys.py` ✅
**Purpose:** Extract danh sách 1,273 food keys từ database

**Status:** ✅ COMPLETED (đã chạy)

**Output:** `food_keys.json` (1,273 food keys)

**Usage:**
```bash
python scripts/extract_food_keys.py
```

---

### 2. `download_mobilenet_v3.py` ⏳
**Purpose:** Download MobileNetV3 embedding model từ TensorFlow Hub

**Requirements:**
```bash
pip install tensorflow tensorflow-hub
```

**Output:** 
- `assets/models/mobilenet_v3_embedding.tflite` (~5-10MB)
- Embedding size: **1280D** (not 512D!)

**Usage:**
```bash
python scripts/download_mobilenet_v3.py
```

**⚠️ IMPORTANT:** Sau khi download, update code:
```dart
// image_embedding_service.dart line 24
static const int _embeddingSize = 1280;
```

---

### 3. `download_from_google_images.py` ⏳ (NEW)
**Purpose:** Tự động download ảnh món ăn từ Google Images

**Requirements:**
```bash
pip install selenium webdriver-manager pillow
```

**Pros:**
- ✅ Tự động
- ✅ Miễn phí
- ✅ Nhiều ảnh

**Cons:**
- ❌ Chậm (~11 hours cho 1,273 ảnh)
- ❌ Google có thể block
- ❌ Quality không đảm bảo

**Usage:**
```bash
python scripts/download_from_google_images.py
```

**Tips:**
- Chạy theo batch (100-200 ảnh/lần)
- Tránh chạy 24/7 (Google sẽ block)
- Verify quality sau khi download

---

### 4. `download_from_pexels.py` ⏳ (NEW - RECOMMENDED)
**Purpose:** Download ảnh từ Pexels API

**Requirements:**
```bash
pip install requests pillow
```

**Setup:**
1. Sign up tại: https://www.pexels.com/api/
2. Get FREE API key
3. Run script

**Pros:**
- ✅ High quality images
- ✅ Fast (~42 minutes cho 1,273 ảnh)
- ✅ Stable API
- ✅ 200 requests/hour (free tier)
- ✅ Commercial use OK

**Cons:**
- ⚠️ Cần API key
- ⚠️ Ít món Việt hơn Google

**Usage:**
```bash
python scripts/download_from_pexels.py
```

**Options:**
1. Download all (1,273 images)
2. Download batch (specify range)
3. Download popular foods only (~100 images)

---

## 🚀 QUICK START GUIDE

### Step 1: Extract Food Keys ✅
```bash
python scripts/extract_food_keys.py
```
**Output:** `food_keys.json` (1,273 keys)

### Step 2: Download Model ⏳
```bash
pip install tensorflow tensorflow-hub
python scripts/download_mobilenet_v3.py
```
**Output:** `assets/models/mobilenet_v3_embedding.tflite`

### Step 3: Download Food Images ⏳

**Option A: Pexels (RECOMMENDED)**
```bash
# Get API key: https://www.pexels.com/api/
pip install requests pillow
python scripts/download_from_pexels.py
```

**Option B: Google Images**
```bash
pip install selenium webdriver-manager pillow
python scripts/download_from_google_images.py
```

**Option C: Manual Collection (BEST for Vietnamese foods)**
```
1. Create: assets/food_images/
2. Collect 1,273 images
3. Naming: {food_key}.jpg (e.g., pho_bo.jpg)
4. Size: ≥224x224 pixels
```

---

## 📊 COMPARISON

```
┌──────────────────┬──────────┬────────┬───────────┬──────────┐
│ Method           │ Speed    │ Quality│ Coverage  │ Effort   │
├──────────────────┼──────────┼────────┼───────────┼──────────┤
│ Manual           │ 3-5 days │ ⭐⭐⭐⭐⭐│ 100%      │ High     │
│ Pexels API       │ 42 min   │ ⭐⭐⭐⭐  │ 60-70%    │ Low      │
│ Google Images    │ 11 hours │ ⭐⭐⭐   │ 80-90%    │ Medium   │
│ Unsplash API     │ 30 min   │ ⭐⭐⭐⭐  │ 50-60%    │ Low      │
└──────────────────┴──────────┴────────┴───────────┴──────────┘
```

---

## 💡 RECOMMENDATIONS

### For Best Accuracy (95%+):
```
1. Manual collection for common foods (~200 món)
2. Pexels API for remaining foods
3. Google Images for missing foods
4. Verify and replace low-quality images
```

### For Quick Testing:
```
1. Pexels API for popular foods (~100 món)
2. Test with subset first
3. Expand gradually
```

### For Production:
```
1. Hire photographer (1-2 days)
2. Chụp 1,273 món with consistent style
3. Best quality & accuracy
```

---

## 📁 OUTPUT STRUCTURE

After running scripts:

```
monitor_food_intake/
├── scripts/
│   ├── food_keys.json                      ✅ (1,273 keys)
│   ├── failed_downloads.json               (if any failed)
│   ├── extract_food_keys.py                ✅
│   ├── download_mobilenet_v3.py            ⏳
│   ├── download_from_google_images.py      ⏳
│   └── download_from_pexels.py             ⏳
│
├── assets/
│   ├── models/
│   │   ├── yolov8n.tflite                  ✅ (existing)
│   │   └── mobilenet_v3_embedding.tflite   ⏳ (need download)
│   │
│   └── food_images/                        ⏳ (need collect)
│       ├── pho_bo.jpg
│       ├── bun_cha.jpg
│       ├── com_trang.jpg
│       └── ... (1,270 more)
```

---

## ⚠️ TROUBLESHOOTING

### Issue: pip install tensorflow fails

**Solution:**
```bash
# Use specific version
pip install tensorflow==2.15.0

# Or use conda
conda install tensorflow
```

### Issue: Google Images script blocked

**Solution:**
1. Wait 1-2 hours before retry
2. Use VPN to change IP
3. Switch to Pexels API
4. Reduce requests per minute

### Issue: Pexels returns no results

**Solution:**
1. Try English-only query
2. Use generic terms (e.g., "rice" instead of "steamed rice")
3. Manually search on pexels.com
4. Use alternative: Unsplash, Pixabay

### Issue: Downloaded images are low quality

**Solution:**
1. Increase target_size to 512x512
2. Adjust JPEG quality to 98
3. Filter out small images (<300px)
4. Manual review & replace

---

## 🎯 NEXT STEPS

### After Scripts Complete:

1. **Verify Images**
   ```bash
   # Check count
   ls assets/food_images/*.jpg | wc -l  # Should be 1273
   ```

2. **Update pubspec.yaml**
   ```yaml
   flutter:
     assets:
       - assets/food_images/
   ```

3. **Update Dart Code**
   ```dart
   // image_embedding_service.dart
   static const int _embeddingSize = 1280;
   ```

4. **Run Flutter App**
   ```bash
   flutter pub get
   flutter run
   ```

5. **Test Image-Based Search**
   ```dart
   final service = HybridImageBasedAnalysisService();
   await service.initialize(foodImagesDir: 'assets/food_images/');
   ```

---

## 📞 SUPPORT

Nếu gặp vấn đề:
1. Check error messages trong console
2. Review DEPLOYMENT_GUIDE.md
3. Check IMAGE_BASED_SEMANTIC_SEARCH.md
4. Run scripts with --verbose flag

---

**🎊 Good luck with image collection!**

Recommended: Start with **Pexels API** (~100 popular foods) for quick testing! 🚀
