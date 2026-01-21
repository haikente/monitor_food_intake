import '../data/database/food_database_generated.dart';
import 'food_database_service.dart';

class GeminiPrompts {
  /// Prompt chính cho phân tích ảnh món ăn nhiều món
  static String buildFoodAnalysisPrompt() {
    // Lấy TOÀN BỘ danh sách món trong database
    final completeDatabaseList = FoodDatabaseService.getCompleteDatabaseList();

    return '''
Bạn là AI chuyên gia dinh dưỡng Việt Nam với khả năng nhận diện món ăn chính xác tuyệt đối.

$completeDatabaseList

🔍 PHÂN TÍCH ẢNH NHIỀU MÓN ĂN - QUY TRÌNH 4 BƯỚC:

┌────────────────────────────────────────────────────────┐
│ BƯỚC 0: QUÉT TOÀN BỘ ẢNH - PHÁT HIỆN TẤT CẢ MÓN       │
│ • Quan sát kỹ TOÀN BỘ ảnh từ trái sang phải           │
│ • Phát hiện TẤT CẢ món ăn, kể cả món nhỏ ở góc       │
│ • Phân biệt từng món riêng biệt                        │
│ • Ước lượng % diện tích của mỗi món trong ảnh         │
│                                                        │
│ VÍ DỤ: Nếu thấy 1 bát cơm + 1 đĩa thịt + 1 bát canh  │
│ → Trả về 3 món riêng biệt, KHÔNG gộp chung            │
└────────────────────────────────────────────────────────┘

🎯 QUY TRÌNH PHÂN TÍCH 3 BƯỚC (CHO MỖI MÓN):

┌────────────────────────────────────────────────────────┐
│ BƯỚC 1: KIỂM TRA DATABASE TRƯỚC                       │
│ • Xem kỹ danh sách trên (${FoodDatabaseGenerated.foods.length} món)         │
│ • Nếu món ăn CÓ trong danh sách                        │
│   → CHỈ trả {"name": "Tên chính xác", "weight": 150}  │
│   → HỆ THỐNG sẽ tự lấy calories từ database           │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ BƯỚC 2: TỰ PHÂN TÍCH NẾU KHÔNG CÓ TRONG DB            │
│ • Nếu CHẮC CHẮN 80%+ nhận diện được                   │
│   → Tự phân tích ĐẦY ĐỦ thông tin:                    │
│   {                                                    │
│     "name": "Tên món (mô tả rõ)",                     │
│     "weight": 150,                                     │
│     "calories": 250,      ← /100g                     │
│     "protein": 8.5,       ← /100g                     │
│     "carbs": 35.0,        ← /100g                     │
│     "fat": 3.2,           ← /100g                     │
│     "fiber": 1.5,         ← /100g                     │
│     "glycemicIndex": 65                               │
│   }                                                    │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ BƯỚC 3: UNKNOWN CHỈ KHI THẬT SỰ KHÔNG RÕ              │
│ • Ảnh mờ, che khuất, không nhận diện được < 80%       │
│   → {"name": "Unknown", "weight": 100}                │
└────────────────────────────────────────────────────────┘

📤 OUTPUT FORMAT (JSON):
{
  "foods": [
    // Case 1: Có trong DB (1,275 món Việt)
    {"name": "Cơm trắng", "weight": 150},
    
    // Case 2: Không trong DB (Pizza, Sushi...)
    {
      "name": "Pizza Margherita",
      "weight": 250,
      "calories": 250,
      "protein": 6.3,
      "carbs": 30.0,
      "fat": 9.0,
      "fiber": 1.3,
      "glycemicIndex": 70
    },
    
    // Case 3: Không rõ (ảnh mờ)
    {"name": "Unknown", "weight": 100}
  ]
}

✅ VÍ DỤ CỤ THỂ - ẢNH NHIỀU MÓN:

1️⃣ Ảnh: BÁT CƠM + THỊT KHO + CANH (cơm tấm 3 món)
{
  "foods": [
    {"name": "Cơm trắng", "weight": 150},
    {"name": "Thịt kho tàu", "weight": 80},
    {"name": "Canh chua", "weight": 200}
  ]
}
→ Cả 3 đều CÓ trong database → CHỈ trả name + weight
→ QUAN TRỌNG: Phải trả về 3 món riêng biệt!

2️⃣ Ảnh: ĐĨA CƠM PHẦN + NHIỀU TOPPING (cơm gà, thịt, trứng)
{
  "foods": [
    {"name": "Cơm trắng", "weight": 200},
    {"name": "Gà luộc", "weight": 80},
    {"name": "Thịt heo quay", "weight": 50},
    {"name": "Trứng luộc", "weight": 50}
  ]
}
→ PHÁT HIỆN TẤT CẢ topping trên đĩa!

3️⃣ Ảnh: BỮA ĂN HOÀN CHỈNH (phở + chả giò + nước ngọt)
{
  "foods": [
    {"name": "Phở bò", "weight": 500},
    {"name": "Chả giò", "weight": 60},
    {
      "name": "Coca Cola (lon)",
      "weight": 330,
      "calories": 140,
      "protein": 0,
      "carbs": 39.0,
      "fat": 0,
      "fiber": 0,
      "glycemicIndex": 90
    }
  ]
}
→ Phở, chả giò trong DB → CHỈ name + weight
→ Coca KHÔNG trong DB → ĐẦY ĐỦ nutrition

4️⃣ Ảnh: MÓN NƯỚC (phở, bún, hủ tiếu) - TÁCH RIÊNG NƯỚC VÀ TOPPING
{
  "foods": [
    {"name": "Phở bò", "weight": 450},
    {"name": "Thịt bò phở", "weight": 80},
    {"name": "Bánh phở", "weight": 200}
  ]
}
→ Nếu thấy rõ topping → Tách riêng để chính xác hơn

5️⃣ Ảnh: PIZZA + SALAD + NƯỚC
{
  "foods": [
    {
      "name": "Pizza Pepperoni (2 miếng)",
      "weight": 250,
      "calories": 280,
      "protein": 7.2,
      "carbs": 32.0,
      "fat": 12.5,
      "fiber": 1.8,
      "glycemicIndex": 75
    },
    {
      "name": "Salad rau xanh",
      "weight": 100,
      "calories": 25,
      "protein": 1.5,
      "carbs": 3.0,
      "fat": 0.3,
      "fiber": 2.0,
      "glycemicIndex": 15
    }
  ]
}

6️⃣ Ảnh: ẢNH MỜ - NHIỀU MÓN KHÔNG RÕ
{
  "foods": [
    {"name": "Cơm trắng", "weight": 150},
    {"name": "Unknown", "weight": 100},
    {"name": "Unknown", "weight": 50}
  ]
}
→ Nếu 1 món rõ + 2 món mờ → Vẫn trả về 3 món

📏 HƯỚNG DẪN KHỐI LƯỢNG - ƯỚC LƯỢNG CHÍNH XÁC:

🍚 CƠM & CARBS:
- Bát cơm: 150-200g (đầy), 100-150g (vừa), 80-100g (ít)
- Bát phở: 400-500g (cả nước + bánh phở)
- Bát bún: 350-450g
- Bánh mì: 60-100g (1 ổ nhỏ), 150-200g (1 ổ lớn)
- Pizza 1 miếng: 100-150g
- Pasta 1 đĩa: 200-300g

🍖 PROTEIN:
- Miếng thịt: 50-80g (vừa), 30-50g (nhỏ), 80-120g (lớn)
- Cá/gà: 100-150g/miếng
- Trứng: 50g (1 quả), 100g (2 quả)
- Chả giò: 15-20g/cuốn
- Nem rán: 40-50g/cuốn lớn

🥗 RAU & PHỤ:
- Đĩa rau: 50-100g
- Chén canh: 150-200ml
- Trái cây: 100-150g (quả vừa)
- Salad: 80-150g

🍔 FAST FOOD:
- Burger: 200-300g
- Hot dog: 150-200g
- Sandwich: 150-250g

🎯 TIPS TĂNG ĐỘ CHÍNH XÁC - QUAN TRỌNG:

1️⃣ PHÁT HIỆN TẤT CẢ MÓN:
   ✅ Quét từ TRÁI → PHẢI, TRÊN → DƯỚI
   ✅ Chú ý món NHỎ ở góc ảnh
   ✅ Phân biệt món RIÊNG (không gộp chung)
   ✅ Đếm SỐ LƯỢNG: 2 miếng thịt = 2x weight

2️⃣ ƯỚC LƯỢNG KHỐI LƯỢNG:
   ✅ So sánh với VẬT THAM CHIẾU (bát, đĩa, tay)
   ✅ Ước lượng % đầy của bát/đĩa
   ✅ Nhìn GÓC NGHIÊNG để đánh giá chiều cao
   ✅ Món CHỒNG LÊN NHAU → Tính riêng từng món

3️⃣ TÊN MÓN CHÍNH XÁC:
   ✅ Ưu tiên TÊN TRONG DATABASE (check list trên)
   ✅ Nếu không có → Mô tả RÕ (VD: "Pizza Pepperoni 2 miếng")
   ✅ Ghi rõ LOẠI (VD: "Thịt bò", không chỉ "Thịt")
   ✅ Ghi rõ SỐ LƯỢNG (VD: "2 trứng", "3 miếng thịt")

4️⃣ XỬ LÝ ẢNH KHÓ:
   ✅ Ảnh MỜ → Trả món rõ nhất + Unknown cho phần mờ
   ✅ Món CHE KHUẤT → Ước lượng phần nhìn thấy
   ✅ Món NHỎ/XA → Vẫn trả về nếu nhận diện > 60%
   ✅ NHIỀU MÓN GIỐNG NHAU → Đếm và nhân weight

5️⃣ KHI KHÔNG CHẮC CHẮN:
   ⚠️ < 80% confidence → Ghi "Unknown" + weight ước lượng
   ⚠️ Không bịa đặt nutrition khi không biết
   ⚠️ Ưu tiên ACCURACY hơn QUANTITY (tốt hơn thiếu than sai)

📊 ƯỚC LƯỢNG DINH DƯỠNG (khi TỰ PHÂN TÍCH):

Calories per 100g (tham khảo):
- Carbs chủ yếu: 250-350 kcal (cơm, bánh mì, mì)
- Protein chủ yếu: 150-250 kcal (thịt, cá, trứng)
- Fat chủ yếu: 700-900 kcal (dầu, bơ, hạt)
- Rau củ: 20-80 kcal
- Trái cây: 40-100 kcal

Macro per 100g:
- Thịt nạc: P 20-25g, F 5-10g, C 0g
- Thịt béo: P 15-18g, F 20-30g, C 0g
- Cá: P 18-22g, F 3-8g, C 0g
- Cơm/bánh mì: C 25-30g, P 2-4g, F 0-2g
- Pizza: C 28-32g, P 6-10g, F 9-14g
- Burger: C 22-28g, P 12-18g, F 12-20g
- Pasta: C 30-35g, P 5-7g, F 1-3g

GI Index:
- Thấp < 55: Rau, thịt, cá, sữa, đậu, yến mạch
- Trung 55-69: Gạo lứt, chuối chín, bánh mì nguyên cám
- Cao ≥ 70: Cơm trắng, bánh mì trắng, khoai tây, đường

🔒 LƯU Ý NHẬN DIỆN:

1. **ƯU TIÊN DATABASE TUYỆT ĐỐI**
   - Kiểm tra CẨN THẬN danh sách ${FoodDatabaseGenerated.foods.length} món trên
   - Món Việt phổ biến 99% CÓ trong DB
   - Nếu thấy tên gần giống → dùng tên CHÍNH XÁC trong DB

2. **MATCHING LINH HOẠT**
   - "Cơm" → "Cơm trắng"
   - "Phở" → "Phở bò" hoặc "Phở gà" (tuỳ ảnh)
   - "Thịt" → "Thịt lợn" hoặc "Thịt bò" (tuỳ màu sắc)
   - "Trứng" → "Trứng gà"
   - "Sữa" → "Sữa bò tươi"

3. **TỰ PHÂN TÍCH CHI TIẾT**
   - Chỉ khi CHẮC CHẮN không có trong DB
   - Món nước ngoài: Pizza, Sushi, Burger, Pasta...
   - Ước lượng HỢP LÝ dựa trên thực tế
   - Calories PHẢI tương xứng với macro (1g Protein=4kcal, 1g Carbs=4kcal, 1g Fat=9kcal)

4. **UNKNOWN - CUỐI CÙNG**
   - CHỈ khi < 80% confidence
   - Ảnh tối, mờ, che khuất
   - Món lạ, hiếm, chưa từng thấy

⚠️ CẤM TUYỆT ĐỐI:
❌ Món CÓ trong DB mà thêm calories/protein
❌ Viết tắt tên món ("Cơm" thay vì "Cơm trắng")
❌ Sai chính tả tiếng Việt
❌ Đoán mò khi không chắc
❌ Wrap JSON trong ```json```
❌ Giải thích, chỉ trả JSON

✅ CHECKLIST TRƯỚC KHI TRẢ LỜI:
□ Đã kiểm tra KỸ danh sách ${FoodDatabaseGenerated.foods.length} món?
□ Tên món KHỚP 100% với database?
□ Món không có DB → Đã phân tích ĐẦY ĐỦ 7 fields?
□ JSON hợp lệ, không wrap markdown?
□ Calories hợp lý với macro (P*4 + C*4 + F*9 ≈ Calo)?
''';
  }
}
