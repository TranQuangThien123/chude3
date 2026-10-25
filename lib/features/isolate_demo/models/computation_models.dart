/// Cấu hình mặc định cho bài toán Thuật toán vòng lặp lớn (Tìm số nguyên tố).
class PrimeWorkloadConfig {
  const PrimeWorkloadConfig._();

  static const String title = 'Thuật toán Vòng lặp lớn (Tìm số nguyên tố)';
  static const String subtitle =
      'Dùng vòng lặp đếm tất cả các số nguyên tố trong khoảng từ 1 đến N';
  static const int defaultSize = 3500000;
  static const int minSize = 1000000;
  static const int maxSize = 8000000;
  static const String unitLabel = 'số tự nhiên';
}

/// Phương thức thực thi tác vụ.
enum ExecutionMode {
  mainThread(
    label: 'Chạy trực tiếp (Main Thread)',
    description: 'Xử lý đồng bộ trên luồng UI',
  ),
  computeIsolate(
    label: 'Chạy ngầm (Hàm compute)',
    description: 'Khởi tạo Worker Isolate riêng biệt',
  );

  const ExecutionMode({
    required this.label,
    required this.description,
  });

  final String label;
  final String description;
}

/// Tham số đầu vào đóng gói để truyền qua `compute(callback, payload)`.
class TaskPayload {
  const TaskPayload({
    required this.workloadSize,
  });

  final int workloadSize;
}

/// Kết quả trả về sau khi hoàn thành tác vụ nặng.
class ComputationResult {
  const ComputationResult({
    required this.executionMode,
    required this.workloadSize,
    required this.durationMs,
    required this.summaryTitle,
    required this.summaryDetail,
    required this.completedAt,
    required this.droppedFramesCount,
  });

  final ExecutionMode executionMode;
  final int workloadSize;
  final int durationMs;
  final String summaryTitle;
  final String summaryDetail;
  final DateTime completedAt;

  /// Số khung hình bị trễ (Jank frames) ghi nhận trong lúc chạy tác vụ.
  final int droppedFramesCount;
}
