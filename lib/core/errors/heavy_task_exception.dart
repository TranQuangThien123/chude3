/// Ngoại lệ tùy chỉnh khi xử lý các tác vụ tính toán nặng hoặc parse dữ liệu.
class HeavyTaskException implements Exception {
  const HeavyTaskException(
    this.message, {
    this.details,
    this.originalError,
  });

  /// Thông báo lỗi thân thiện cho người dùng.
  final String message;

  /// Chi tiết kỹ thuật bổ sung (nếu có).
  final String? details;

  /// Lỗi gốc phát sinh từ hệ thống.
  final Object? originalError;

  @override
  String toString() {
    if (details != null && details!.isNotEmpty) {
      return 'HeavyTaskException: $message ($details)';
    }
    return 'HeavyTaskException: $message';
  }
}
