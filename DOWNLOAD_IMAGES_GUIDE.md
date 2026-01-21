# 🚀 HƯỚNG DẪN DOWNLOAD 1,275 ẢNH MÓN ĂN

## 📋 YÊU CẦU

1. **Pexels API Key** (MIỄN PHÍ):
   - Đăng ký tại: https://www.pexels.com/api/
   - Free tier: 200 requests/hour, 20,000/month
   - Đủ để download 1,275 ảnh trong ~45 phút

2. **Python dependencies**:
   ```bash
   pip install requests pillow
   ```

## 🎯 CÁCH SỬ DỤNG

### Option 1: Quick Start (Recommended)

1. **Lấy API key**:
   - Vào https://www.pexels.com/api/
   - Sign up (free)
   - Copy API key

2. **Tạo file `.env`** ở root project:
   ```
   PEXELS_API_KEY=your_key_here
   ```

3. **Chạy script**:
   ```bash
   cd c:\Users\OS\.vscode\test\AI_monitor_food\monitor_food_intake
   python scripts/download_food_images_optimized.py
   ```

### Option 2: Hardcode API Key

Nếu không muốn dùng .env file, edit file `download_food_images_optimized.py`:

```python
# Line 36
PEXELS_API_KEY = "YOUR_ACTUAL_API_KEY_HERE"
```

## 📊 QUÁ TRÌNH DOWNLOAD

```
🚀 Starting download...
⏱️  Estimated time: ~42 minutes

[1/1275] 🔍 Searching: Phở bò (Query 1: 'Beef Pho food')
          ✅ Downloaded: pho_bo.jpg

[2/1275] 🔍 Searching: Cơm trắng (Query 1: 'Steamed rice food')
          ✅ Downloaded: com_trang.jpg

[3/1275] 🔍 Searching: Bún bò Huế (Query 1: 'Hue beef noodle soup food')
          ⚠️  No results, trying next query...
          🔍 Trying Query 2: 'Bun bo Hue Vietnamese food'
          ✅ Downloaded: bun_bo_hue.jpg

📊 Progress: 50/1275 (3.9%)
⏱️  Elapsed: 1.8m | Remaining: ~40.2m

...

🎉 DOWNLOAD COMPLETE!
====================================
📊 Statistics:
   Total foods:      1275
   ✅ Downloaded:    1150 (90.2%)
   ⏭️  Already existed: 0
   ❌ Failed:        125 (9.8%)

⏱️  Total time: 42.5 minutes
📁 Images saved to: assets/data/food_images
📝 Failed log saved to: failed_downloads.json

✨ Success rate: 90.2%
```

## 🎨 TÍNH NĂNG ƯU VIỆT

### ✅ Smart Search Strategy
Script thử 3 query strategies theo thứ tự:
1. **English name + "food"** (highest success rate)
   - "Beef Pho food"
   - "Spring rolls food"

2. **Vietnamese name (romanized) + "Vietnamese food"**
   - "Pho bo Vietnamese food"
   - "Banh mi Vietnamese food"

3. **English name only** (fallback)
   - "Beef Pho"
   - "Spring rolls"

### ✅ Resume Capability
- Nếu script bị dừng giữa chừng, chạy lại sẽ **SKIP** các ảnh đã tải
- Tiết kiệm API calls và thời gian

### ✅ Quality Validation
- Tự động reject ảnh < 5KB (corrupted/blank)
- Resize về 224x224 (perfect cho MobileNetV3)
- JPEG format, quality 95%

### ✅ Failed Downloads Tracking
File `failed_downloads.json` lưu:
```json
{
  "banh_pia": {
    "name_vn": "Bánh pía",
    "name_en": "Pia cake",
    "queries_tried": [
      "Pia cake food",
      "Banh pia Vietnamese food",
      "Pia cake"
    ]
  }
}
```

→ Có thể manual download sau cho các món hiếm

### ✅ Progress Tracking
- Progress bar mỗi 50 images
- Thời gian còn lại (estimated)
- Success rate real-time

## 📈 DỰ ĐOÁN KẾT QUẢ

| Metric | Expected |
|--------|----------|
| **Success Rate** | 85-92% (~1,100/1,275) |
| **Time** | 40-50 minutes |
| **API Calls** | ~2,000 (under free limit) |
| **Storage** | ~200MB |

### Các món dễ download (90%+):
- ✅ Món phổ biến: Phở, Cơm, Bún, Bánh mì
- ✅ Món có tên English: Spring rolls, Fried rice
- ✅ Món nổi tiếng quốc tế: Pho, Banh mi

### Các món khó download (50-70%):
- ⚠️ Món địa phương hiếm: Bánh đa cua, Chả rươi
- ⚠️ Món có tên khó dịch: Nem chua, Mắm tôm
- ⚠️ Món ít phổ biến: Các món đặc sản vùng miền

## 🔧 XỬ LÝ THẤT BẠI

Nếu có món không download được:

### Option 1: Manual Download
```bash
# Check failed_downloads.json
# Download manually từ Google Images hoặc nguồn khác
# Đặt tên file theo format: {food_key}.jpg
# Resize về 224x224
# Save vào: assets/data/food_images/
```

### Option 2: Alternative Script (Google Images)
```bash
python scripts/download_from_google_images.py
# Slower (~11 hours) but more comprehensive
```

### Option 3: Skip Rare Foods
- Chỉ cần 90% ảnh (1,150 món) cũng đủ tốt
- Các món hiếm ít xuất hiện trong bữa ăn thực tế
- Image Anchor vẫn work với 1,150 món

## 🎯 SAU KHI DOWNLOAD XONG

1. **Verify images**:
   ```bash
   # Check số lượng
   ls assets/data/food_images/*.jpg | wc -l
   # Should show ~1,100-1,150
   ```

2. **Next steps**:
   - ✅ Generate embeddings: `python scripts/generate_food_embeddings.py`
   - ✅ Integrate to database: `dart scripts/integrate_embeddings_to_database.dart`
   - ✅ Test Image Anchor: Run app with Enhanced Hybrid mode

## 💡 TIPS

1. **Chạy ban đêm**: Script mất ~45 phút, có thể chạy overnight

2. **Không cần ngồi đợi**: Script tự động, có progress log

3. **API limits**: 200 req/hour, script dùng 2s delay = 1,800 req/hour max
   - Nếu bị rate limit, script sẽ báo lỗi
   - Chờ 1 giờ rồi chạy lại (resume từ đâu dừng)

4. **Backup**: Sau khi download xong, nên backup folder `assets/data/food_images/`

## 🚀 BẮT ĐẦU NGAY

```bash
# 1. Install dependencies
pip install requests pillow

# 2. Get API key
# Visit: https://www.pexels.com/api/

# 3. Add to .env
echo "PEXELS_API_KEY=your_key_here" >> .env

# 4. Run
python scripts/download_food_images_optimized.py

# 5. Grab coffee ☕ and wait ~45 minutes
```

---

**Ready?** Bắt đầu download để implement Image Anchor! 🎯
