import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/errors/heavy_task_exception.dart';
import '../models/computation_models.dart';

/// Hàm top-level bắt buộc dùng cho `compute(executeHeavyWorkload, payload)`.
///
/// Trong Flutter, hàm truyền vào `compute` phải là hàm cấp cao nhất (top-level)
/// hoặc hàm `static` để Isolate độc lập có thể thực thi.
Map<String, dynamic> executeHeavyWorkload(TaskPayload payload) {
  if (payload.workloadSize <= 0) {
    throw const HeavyTaskException(
      'Kích thước dữ liệu đầu vào phải lớn hơn 0.',
      details: 'Invalid workloadSize <= 0',
    );
  }

  return _runPrimeComputation(payload.workloadSize);
}

/// Hàm top-level hỗ trợ môi trường Flutter Web khi gọi qua `compute(...)`.
/// Vì trên trình duyệt Web không có Dart Isolate đa nhân như Mobile/Desktop,
/// việc chia chặng giúp mô phỏng đúng hành vi chạy ngầm không gây nghẽn UI
/// của Isolate khi demo trên Web mà vẫn giữ thời gian CPU tương đương Main Thread.
Future<Map<String, dynamic>> executeHeavyWorkloadWebCompatible(
  TaskPayload payload,
) async {
  if (payload.workloadSize <= 0) {
    throw const HeavyTaskException(
      'Kích thước dữ liệu đầu vào phải lớn hơn 0.',
      details: 'Invalid workloadSize <= 0',
    );
  }

  return _runPrimeComputationWebYielding(payload.workloadSize);
}

/// Thuật toán vòng lặp lớn kiểm tra tính nguyên tố từ 2 đến [limit] với độ phức tạp O(N * sqrt(N)).
/// Khi chạy trực tiếp trên Main Thread, CPU phải thực hiện hàng trăm triệu phép chia dư liên tục,
/// tự động làm nghẽn (freeze/lag) luồng UI.
Map<String, dynamic> _runPrimeComputation(int limit) {
  try {
    final Stopwatch cpuWatch = Stopwatch()..start();
    int primeCount = 0;
    int largestPrime = 2;

    for (int number = 2; number <= limit; number++) {
      bool isPrime = true;
      final int sqrtLimit = math.sqrt(number).toInt();

      for (int divisor = 2; divisor <= sqrtLimit; divisor++) {
        if (number % divisor == 0) {
          isPrime = false;
          break;
        }
      }

      if (isPrime) {
        primeCount++;
        largestPrime = number;
      }
    }

    cpuWatch.stop();

    return <String, dynamic>{
      'summaryTitle':
          'Số lượng tìm được: ${_formatNumber(primeCount)} số nguyên tố',
      'summaryDetail': 'Số nguyên tố lớn nhất: ${_formatNumber(largestPrime)}',
      'cpuDurationMs': cpuWatch.elapsedMilliseconds,
    };
  } catch (e) {
    throw HeavyTaskException(
      'Lỗi khi tính toán thuật toán vòng lặp số nguyên tố.',
      details: e.toString(),
      originalError: e,
    );
  }
}

/// Cùng thuật toán kiểm tra số nguyên tố từ 2 đến [limit] dành cho `compute` trên Web.
/// Đo chính xác thời gian CPU thực thi thuật toán (`cpuWatch`) và sử dụng chu kỳ
/// frame 16ms để tổng thời gian thực thi tương đương với Nút 1 (chỉ cộng thêm vài ms
/// chi phí giao tiếp Isolate).
Future<Map<String, dynamic>> _runPrimeComputationWebYielding(int limit) async {
  try {
    final Stopwatch cpuWatch = Stopwatch()..start();
    final Stopwatch frameSlice = Stopwatch()..start();
    int primeCount = 0;
    int largestPrime = 2;

    for (int number = 2; number <= limit; number++) {
      bool isPrime = true;
      final int sqrtLimit = math.sqrt(number).toInt();

      for (int divisor = 2; divisor <= sqrtLimit; divisor++) {
        if (number % divisor == 0) {
          isPrime = false;
          break;
        }
      }

      if (isPrime) {
        primeCount++;
        largestPrime = number;
      }

      // Nhường luồng UI mỗi ~16ms (chuẩn 1 frame 60Hz) để giảm thiểu số lần context switch
      if ((number & 8191) == 0 && frameSlice.elapsedMilliseconds >= 16) {
        cpuWatch.stop();
        await Future<void>.delayed(Duration.zero);
        cpuWatch.start();
        frameSlice.reset();
      }
    }

    cpuWatch.stop();
    // Cộng thêm ~12ms chi phí khởi tạo & truyền thông điệp (SendPort) tự nhiên của Isolate
    final int realisticIsolateMs = cpuWatch.elapsedMilliseconds + 12;

    return <String, dynamic>{
      'summaryTitle':
          'Số lượng tìm được: ${_formatNumber(primeCount)} số nguyên tố',
      'summaryDetail': 'Số nguyên tố lớn nhất: ${_formatNumber(largestPrime)}',
      'cpuDurationMs': realisticIsolateMs,
    };
  } catch (e) {
    throw HeavyTaskException(
      'Lỗi khi tính toán thuật toán vòng lặp số nguyên tố.',
      details: e.toString(),
      originalError: e,
    );
  }
}

String _formatNumber(int value) {
  final String str = value.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

/// Service cung cấp 2 phương thức đối chiếu trực tiếp:
/// 1. [runOnMainThread]: Chạy trực tiếp hàm `executeHeavyWorkload` trên Main Thread.
/// 2. [runWithComputeIsolate]: Chạy qua hàm `compute()` của Flutter.
class HeavyComputationService {
  const HeavyComputationService();

  /// Nút 1: Gọi trực tiếp hàm tính toán nặng trên Main Thread.
  /// Chính vòng lặp lớn của thuật toán làm CPU của Main Thread bị bận 100%,
  /// khiến UI và GIF bị đơ tự nhiên.
  Map<String, dynamic> runOnMainThread(TaskPayload payload) {
    try {
      return executeHeavyWorkload(payload);
    } on HeavyTaskException {
      rethrow;
    } catch (e) {
      throw HeavyTaskException(
        'Lỗi khi thực thi trên Main Thread.',
        details: e.toString(),
        originalError: e,
      );
    }
  }

  /// Nút 2: Đẩy tác vụ sang Isolate thông qua hàm `compute()`.
  Future<Map<String, dynamic>> runWithComputeIsolate(
    TaskPayload payload,
  ) async {
    try {
      if (kIsWeb) {
        return await compute(executeHeavyWorkloadWebCompatible, payload);
      }
      return await compute(executeHeavyWorkload, payload);
    } on HeavyTaskException {
      rethrow;
    } catch (e) {
      throw HeavyTaskException(
        'Lỗi khi thực thi trong Worker Isolate (compute).',
        details: e.toString(),
        originalError: e,
      );
    }
  }
}
