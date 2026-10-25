import 'package:flutter/material.dart';

import '../../../../core/errors/heavy_task_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/computation_models.dart';
import '../../services/heavy_computation_service.dart';
import '../widgets/computation_result_card.dart';
import '../widgets/smooth_animation_showcase.dart';

/// Màn hình chính minh họa Chủ đề 03:
/// Xử lý tác vụ nặng với Isolate (`compute`) để giữ mượt giao diện.
class IsolateDemoScreen extends StatefulWidget {
  const IsolateDemoScreen({super.key});

  @override
  State<IsolateDemoScreen> createState() => _IsolateDemoScreenState();
}

class _IsolateDemoScreenState extends State<IsolateDemoScreen> {
  final HeavyComputationService _computationService =
      const HeavyComputationService();

  double _workloadSize = PrimeWorkloadConfig.defaultSize.toDouble();

  bool _isComputing = false;
  ExecutionMode? _activeMode;
  String? _errorMessage;
  final List<ComputationResult> _history = <ComputationResult>[];

  /// Thực thi tác vụ nặng theo chế độ được chọn:
  /// - [ExecutionMode.mainThread]: Chạy trực tiếp trên Main Thread (gây đơ cứng UI ~3s).
  /// - [ExecutionMode.computeIsolate]: Chạy qua hàm `compute` (giữ mượt UI 100%).
  Future<void> _executeWorkload(ExecutionMode mode) async {
    if (_isComputing) return;

    setState(() {
      _isComputing = true;
      _activeMode = mode;
      _errorMessage = null;
    });

    // Chờ 50ms để giao diện kịp hiển thị trạng thái chuẩn bị trước khi Main Thread bị chặn
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final Stopwatch stopwatch = Stopwatch()..start();

    final TaskPayload payload = TaskPayload(
      workloadSize: _workloadSize.round(),
    );

    try {
      late final Map<String, dynamic> rawOutput;

      if (mode == ExecutionMode.mainThread) {
        // NÚT 1: Chạy trực tiếp trên Main Thread -> Gây ĐƠ CỨNG giao diện
        rawOutput = _computationService.runOnMainThread(payload);
      } else {
        // NÚT 2: Chạy ngầm qua hàm compute() -> Ảnh GIF & nút Test Chạm vẫn mượt mà
        rawOutput = await _computationService.runWithComputeIsolate(payload);
      }

      stopwatch.stop();

      if (!mounted) return;

      final int effectiveDurationMs =
          (rawOutput['cpuDurationMs'] as int?) ?? stopwatch.elapsedMilliseconds;

      final int droppedFrames = mode == ExecutionMode.mainThread
          ? (effectiveDurationMs / 16.6).round()
          : 0;

      final ComputationResult result = ComputationResult(
        executionMode: mode,
        workloadSize: payload.workloadSize,
        durationMs: effectiveDurationMs,
        summaryTitle: rawOutput['summaryTitle'] as String? ?? 'Hoàn tất xử lý',
        summaryDetail: rawOutput['summaryDetail'] as String? ?? '',
        completedAt: DateTime.now(),
        droppedFramesCount: droppedFrames,
      );

      setState(() {
        _history.insert(0, result);
      });
    } on HeavyTaskException catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi không mong muốn: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isComputing = false;
          _activeMode = null;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Chủ đề 03: Xử lý tác vụ nặng với Isolate (compute)'),
            Text(
              'So sánh UI Freeze (Main Thread) và Đa luồng mượt mà (Hàm compute)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. Khu vực hiển thị Animation GIF lớn, Vòng xoay & Nút Test Chạm
                  SmoothAnimationShowcase(isRunning: _isComputing),
                  const SizedBox(height: 16),

                  // 2. Khu vực cấu hình Thuật toán Vòng lặp lớn & 2 Nút bấm đối chiếu
                  _buildControlPanelCard(),
                  const SizedBox(height: 16),

                  // 3. Khu vực kết quả thực thi & Lịch sử so sánh
                  ComputationResultCard(
                    latestResult: _history.isNotEmpty ? _history.first : null,
                    history: _history,
                    errorMessage: _errorMessage,
                    onClearHistory: () {
                      setState(() {
                        _history.clear();
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanelCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.functions_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PrimeWorkloadConfig.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              PrimeWorkloadConfig.subtitle,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),

            // Thanh trượt chỉnh độ nặng của vòng lặp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Tìm số nguyên tố từ 1 đến N:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatNumber(_workloadSize.round())} ${PrimeWorkloadConfig.unitLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _workloadSize,
              min: PrimeWorkloadConfig.minSize.toDouble(),
              max: PrimeWorkloadConfig.maxSize.toDouble(),
              divisions: 14,
              onChanged: _isComputing
                  ? null
                  : (double value) {
                      setState(() {
                        _workloadSize = value;
                      });
                    },
            ),
            const Divider(height: 20),

            // HAI NÚT BẤM TRỌNG TÂM
            Row(
              children: <Widget>[
                // NÚT 1: Chạy trực tiếp (Main Thread)
                Expanded(
                  child: _buildActionButton(
                    mode: ExecutionMode.mainThread,
                    title: 'Chạy trực tiếp (Main Thread)',
                    subtitle: 'Xử lý đồng bộ trên luồng UI',
                    icon: Icons.warning_amber_rounded,
                    backgroundColor: AppTheme.dangerColor,
                  ),
                ),
                const SizedBox(width: 12),
                // NÚT 2: Chạy ngầm (Hàm compute)
                Expanded(
                  child: _buildActionButton(
                    mode: ExecutionMode.computeIsolate,
                    title: 'Chạy ngầm (Hàm compute)',
                    subtitle: 'Khởi tạo Worker Isolate riêng biệt',
                    icon: Icons.rocket_launch_rounded,
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required ExecutionMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final bool isThisModeRunning = _isComputing && _activeMode == mode;

    return InkWell(
      onTap: _isComputing ? null : () => _executeWorkload(mode),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isComputing && !isThisModeRunning
              ? const Color(0xFFF1F5F9)
              : backgroundColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isComputing && !isThisModeRunning
                ? const Color(0xFFCBD5E1)
                : backgroundColor,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isThisModeRunning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: backgroundColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isThisModeRunning ? 'Đang tìm số nguyên tố...' : subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
