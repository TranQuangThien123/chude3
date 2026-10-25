# Chủ đề 03: Xử lý tác vụ nặng với Isolate (Hàm `compute`) để giữ mượt giao diện

Ứng dụng Flutter minh họa trực quan hiện tượng **nghẽn luồng giao diện (UI Jank / Freeze)** khi thực thi thuật toán tính toán nặng trên **Main Thread** và giải pháp xử lý đa luồng mượt mà bằng hàm **`compute()` (Worker Isolate)**.

---

## 👥 Thành viên thực hiện

| STT | Họ và tên | Vai trò & Phân công nhiệm vụ |
| :-: | :--- | :--- |
| 1 | **Trần Quang Thiên** (`@TranQuangThien123`) | - Khởi tạo kiến trúc dự án (Clean Architecture), cấu hình Theme (`AppTheme`) và xử lý ngoại lệ (`HeavyTaskException`).<br>- Xây dựng Models dữ liệu và Service tính toán thuật toán vòng lặp lớn (`HeavyComputationService`) với Main Thread & `compute()`. |
| 2 | **Nguyễn Đình Hoàn** (`@ndhoan31`) | - Xây dựng khu vực kiểm tra độ mượt UI (`SmoothAnimationShowcase`) hỗ trợ giải mã GIF đa khung hình và kiểm tra tương tác chạm.<br>- Xây dựng màn hình chính (`IsolateDemoScreen`), bảng đối chiếu kết quả (`ComputationResultCard`), kiểm thử tự động (`widget_test.dart`) và tài liệu `README.md`. |

---

## 🎯 Tính năng chính của ứng dụng Demo

1. **Kiểm tra độ mượt giao diện (UI)**:
   - Hiển thị hiệu ứng chuyển động liên tục và hỗ trợ tải file `.gif` bất kỳ từ máy tính lên để kiểm chứng trực quan.
   - Tích hợp vòng xoay `CircularProgressIndicator` và nút **Test Chạm** để kiểm tra độ nhạy của giao diện trong lúc thuật toán đang chạy.
2. **Tác vụ tính toán nặng (Thuật toán Vòng lặp lớn)**:
   - Dùng vòng lặp kiểm tra và đếm tất cả các số nguyên tố trong khoảng từ `1` đến `N` (tùy chỉnh từ `1.000.000` đến `8.000.000`).
3. **So sánh 2 phương thức thực thi**:
   - **Nút 1 – Chạy trực tiếp (Main Thread)**: Xử lý đồng bộ ngay trên luồng UI làm giao diện, ảnh GIF và nút bấm bị đơ cứng tạm thời.
   - **Nút 2 – Chạy ngầm (Hàm `compute`)**: Khởi tạo Worker Isolate riêng biệt giúp giao diện và ảnh GIF giữ nguyên độ mượt mà trong suốt quá trình tính toán.
4. **Kết quả & Lịch sử chạy**:
   - Thống kê số lượng số nguyên tố tìm được, số nguyên tố lớn nhất, thời gian xử lý (`ms`) và lưu lịch sử đối chiếu giữa các lần chạy.

---

## 📂 Cấu trúc thư mục dự án

```text
lib/
├── main.dart                                                # Điểm khởi chạy ứng dụng
├── core/
│   ├── errors/
│   │   └── heavy_task_exception.dart                        # Ngoại lệ tùy chỉnh (Custom Exception)
│   └── theme/
│       └── app_theme.dart                                   # Cấu hình giao diện Material 3
└── features/
    └── isolate_demo/
        ├── models/
        │   └── computation_models.dart                      # Cấu hình tải công việc, Payload & Kết quả
        ├── services/
        │   └── heavy_computation_service.dart               # Hàm top-level & Service chạy Main Thread / compute()
        └── presentation/
            ├── screens/
            │   └── isolate_demo_screen.dart                 # Màn hình điều khiển chính
            └── widgets/
                ├── smooth_animation_showcase.dart           # Khung hiển thị Animation / GIF & nút Test Chạm
                └── computation_result_card.dart             # Bảng hiển thị kết quả & lịch sử chạy
```

---

## ⚙️ Yêu cầu hệ thống & Hướng dẫn cài đặt

### 1. Yêu cầu môi trường
- **Flutter SDK**: `>= 3.13.0`
- **Dart SDK**: `>= 3.13.0`
- Trình duyệt **Chrome / Edge** (nếu chạy trên Flutter Web) hoặc **Android Studio / VS Code** kèm máy ảo Android/iOS/Windows.

### 2. Các bước cài đặt

**Bước 1: Clone dự án từ GitHub**
```bash
git clone https://github.com/TranQuangThien123/chude3.git
cd chude3
```

**Bước 2: Cài đặt các thư viện phụ thuộc (Dependencies)**
```bash
flutter pub get
```

**Bước 3: Cấu hình biến môi trường (`.env`) / Dịch vụ bên thứ ba**
> **Lưu ý**: Dự án tập trung minh họa cơ chế **Dart Isolate & hàm `compute()`** cục bộ của Flutter SDK (`flutter/foundation.dart`), **không** sử dụng API bên thứ ba hay Firebase nên **không bắt buộc** phải cấu hình file `.env` hoặc `google-services.json`.  
> *(Nếu mở rộng dự án trong tương lai, bạn có thể tham khảo file mẫu `.env.example` ở thư mục gốc và sao chép thành `.env`)*.

**Bước 4: Chạy ứng dụng**
- Chạy trên trình duyệt Web (Chrome):
  ```bash
  flutter run -d chrome
  ```
- Chạy trên thiết bị mặc định (Windows / Android / iOS):
  ```bash
  flutter run
  ```

---

## 🧪 Kiểm tra chất lượng mã nguồn (Analyze & Unit/Widget Tests)

- Kiểm tra quy chuẩn code (`flutter_lints`):
  ```bash
  flutter analyze
  ```
- Chạy bộ kiểm thử tự động:
  ```bash
  flutter test
  ```
