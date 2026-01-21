# 🖼️ Image-Based Ensemble Architecture (Experimental)

Cơ chế này hoàn toàn khác với cách tiếp cận "Nhận diện tên món" truyền thống. Thay vì cố gắng **đọc tên** món ăn (Classification), hệ thống này tìm kiếm **ảnh tương đồng** (Visual Similarity).

## 📊 Sơ đồ quy trình (Workflow)

```mermaid
graph TD
    Start([📸 Ảnh Input]) --> YOLO[👁️ YOLOv8 (Detect)]
    YOLO -->|Cắt vùng món ăn| Crop[✂️ Cropped Image]
    
    subgraph "Visual Search Engine"
        Crop --> MobileNet[🧠 Image Embedding Model]
        MobileNet -->|Vector 512 chiều| QueryVec[Feature Vector]
        
        DB_Images[(📂 Database Images)] -->|Pre-computed| DB_Vecs[Database Vectors]
        
        QueryVec <-->|Cosine Similarity| DB_Vecs
        DB_Vecs -->|Match > 60%| Match[✅ Tìm thấy món giống nhất]
    end
    
    Match -->|Tên món: Phở Bò| Gemini[⚖️ Gemini (Weight Only)]
    Gemini -->|Ước lượng: 450g| Calc[🧮 Tính Dinh Dưỡng]
    
    Calc --> End([✅ Kết quả cuối cùng])
```

## 🧩 Chi tiết từng bước

### 1. Detection (YOLOv8)
- **Vai trò**: Tìm "đâu là món ăn" trong hình.
- **Tại sao cần**: Để loại bỏ nhiễu nền (bàn ghế, đũa thìa), giúp bước so sánh ảnh chính xác hơn.

### 2. Feature Extraction (MobileNet V3)
- **Model**: `mobilenet_v3_embedding.tflite`
- **Input**: Ảnh món ăn đã crop.
- **Output**: Một dãy số (Vector) gồm **512 số thực**.
- **Ý nghĩa**: Dãy số này đại diện cho "đặc điểm hình ảnh" (màu sắc, kết cấu, hình dáng). Ví dụ: Phở sẽ có vector gần giống Bún hơn là so với Bánh mì.

### 3. Visual Search (Vector Search)
- **Cơ chế**: So sánh Vector của ảnh vừa chụp với Vector của 1,275 món trong Database.
- **Thuật toán**: `Cosine Similarity`.
- **Ưu điểm**:
  - Không cần model phải "học" tên món trước.
  - Chỉ cần **có ảnh mẫu** trong folder `assets/data` là nhận diện được.
  - Phân biệt tốt các món nhìn giống nhau mà AI thường nhầm tên.

### 4. Weight Estimation (Gemini Lite)
- **Vai trò**: Ước lượng khối lượng.
- **Cách làm**: Gửi ảnh + Tên món (đã tìm thấy ở bước 3) cho Gemini.
- **Prompt đơn giản**: "Đây là Phở Bò, hãy nhìn ảnh và đoán xem bát này nặng bao nhiêu gram?".
- **Tại sao tách riêng**: Gemini rất giỏi suy luận ngữ cảnh (bát to/nhỏ) để đoán lượng ăn, nhưng đôi khi nhận diện tên món không chuẩn bằng Visual Search chuyên biệt.

## 🆚 So sánh với Hybrid Mode cũ

| Đặc điểm | Hybrid Mode (Cũ) | Image Ensemble Mode (Mới) |
| :--- | :--- | :--- |
| **Cốt lõi** | Nhận diện tên (Classification) | So sánh ảnh (Visual Search) |
| **Model** | EfficientNet-Lite4 | MobileNet Embedding |
| **Dữ liệu** | Cần train model trước | Cần thư viện ảnh mẫu (.jpg) |
| **Thêm món mới** | Phải train lại model (Khó) | Chỉ cần copy ảnh vào folder (Dễ) |
| **Điểm mạnh** | Món phổ biến nhận rất nhanh | Nhận được món lạ/đặc thù của quán |
| **Điểm yếu** | Fail nếu món không có trong tập train | Cần thư viện ảnh mẫu chuẩn |

---
> **💡 Kết luận**: Mode này cực kỳ mạnh mẽ nếu bạn xây dựng được bộ dữ liệu ảnh mẫu chuẩn cho 1,275 món ăn Việt Nam. Nó biến app thành một công cụ "Google Lens" phiên bản nội bộ (Offline-capable phase 1).
