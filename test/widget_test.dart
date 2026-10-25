import 'package:chude3/core/errors/heavy_task_exception.dart';
import 'package:chude3/features/isolate_demo/models/computation_models.dart';
import 'package:chude3/features/isolate_demo/services/heavy_computation_service.dart';
import 'package:chude3/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeavyComputationService Unit Tests', () {
    const HeavyComputationService service = HeavyComputationService();

    test(
      'Thực thi thuật toán vòng lặp số nguyên tố trên Main Thread và compute cho cùng kết quả',
      () async {
        const TaskPayload payload = TaskPayload(workloadSize: 1000);

        final Map<String, dynamic> mainResult = service.runOnMainThread(
          payload,
        );
        final Map<String, dynamic> isolateResult = await service
            .runWithComputeIsolate(payload);

        expect(
          mainResult['summaryTitle'],
          equals(isolateResult['summaryTitle']),
        );
        expect(
          mainResult['summaryDetail'],
          equals(isolateResult['summaryDetail']),
        );
      },
    );

    test(
      'Xử lý ngoại lệ chặt chẽ khi workloadSize không hợp lệ (<= 0)',
      () async {
        const TaskPayload invalidPayload = TaskPayload(workloadSize: 0);

        expect(
          () => service.runOnMainThread(invalidPayload),
          throwsA(isA<HeavyTaskException>()),
        );

        await expectLater(
          service.runWithComputeIsolate(invalidPayload),
          throwsA(isA<HeavyTaskException>()),
        );
      },
    );
  });

  testWidgets('Hiển thị khung GIF, nút Chọn GIF và 2 nút bấm đối chiếu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IsolateDemoApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Chọn GIF từ máy'), findsOneWidget);
    expect(find.text('Test Chạm (0)'), findsOneWidget);
    expect(find.text('Chạy trực tiếp (Main Thread)'), findsOneWidget);
    expect(find.text('Xử lý đồng bộ trên luồng UI'), findsOneWidget);
    expect(find.text('Chạy ngầm (Hàm compute)'), findsOneWidget);
    expect(find.text('Khởi tạo Worker Isolate riêng biệt'), findsOneWidget);
    expect(find.textContaining('JSON'), findsNothing);
  });
}
