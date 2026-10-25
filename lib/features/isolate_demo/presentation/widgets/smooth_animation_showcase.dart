import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Khu vực hiển thị Animation GIF kích thước lớn (170x170), vòng xoay kiểm chứng
/// và nút "Test Chạm".
///
/// Đặc biệt: Sử dụng bộ giải mã đa khung hình (`ui.instantiateImageCodec`)
/// trong [_AnimatedGifMemoryPlayer] để tách và phát liên tục từng frame của file
/// GIF người dùng tải lên. Cách này khắc phục triệt để lỗi `Image.memory`
/// chỉ hiển thị frame đầu tiên trên Flutter Web / CanvasKit, đồng thời:
/// - Khi bấm Nút 1 (Main Thread): Timer chuyển frame bị chặn -> Ảnh GIF ĐƠ CỨNG.
/// - Khi bấm Nút 2 (Hàm compute): Ảnh GIF vẫn nhảy múa mượt mà từng frame!
class SmoothAnimationShowcase extends StatefulWidget {
  const SmoothAnimationShowcase({
    super.key,
    required this.isRunning,
  });

  final bool isRunning;

  @override
  State<SmoothAnimationShowcase> createState() =>
      _SmoothAnimationShowcaseState();
}

class _SmoothAnimationShowcaseState extends State<SmoothAnimationShowcase> {
  /// Dữ liệu bytes của file GIF được người dùng chọn từ máy tính.
  Uint8List? _gifBytes;

  /// Key duy nhất chỉ khởi tạo lại khi người dùng thực sự chọn một file GIF mới.
  Key _gifKey = UniqueKey();

  /// Tên file GIF đã chọn (nếu có).
  String? _gifFileName;

  /// Bộ đếm kiểm tra tương tác chạm tức thì khi tác vụ đang chạy.
  int _interactiveTapCount = 0;

  Future<void> _pickGifFromDevice() async {
    try {
      final PlatformFile? pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: <String>['gif'],
      );

      if (pickedFile != null) {
        final Uint8List bytes = await pickedFile.readAsBytes();
        if (bytes.isNotEmpty && mounted) {
          setState(() {
            _gifBytes = bytes;
            _gifKey = UniqueKey();
            _gifFileName = pickedFile.name;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể đọc file GIF đã chọn: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  void _resetToDefaultAnimation() {
    setState(() {
      _gifBytes = null;
      _gifKey = UniqueKey();
      _gifFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCustomGif = _gifBytes != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.motion_photos_on_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Kiểm tra độ mượt giao diện (UI)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Quan sát hiệu ứng chuyển động và bấm thử nút Test Chạm trong lúc đang tính toán',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 28,
                runSpacing: 20,
                children: <Widget>[
                  // Khung hiển thị ảnh GIF lớn (170x170) nằm cân đối ở giữa
                  RepaintBoundary(
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: const Color(0xFF090D16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasCustomGif
                          ? _AnimatedGifMemoryPlayer(
                              key: _gifKey,
                              gifBytes: _gifBytes!,
                            )
                          : const _DefaultSmoothOrbitAnimation(),
                    ),
                  ),

                  // Cột bên cạnh: Vòng xoay CircularProgressIndicator + Nút Test Chạm + Nút Đổi GIF
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Vòng xoay CircularProgressIndicator chạy liên tục bên cạnh ảnh GIF
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  widget.isRunning
                                      ? 'Đang tìm số nguyên tố...'
                                      : 'Trạng thái: Sẵn sàng',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Nút Test Chạm (đếm số lần bấm)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _interactiveTapCount++;
                              });
                            },
                            icon: const Icon(Icons.touch_app_rounded, size: 18),
                            label: Text(
                              'Test Chạm ($_interactiveTapCount)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Nút Chọn / Đổi GIF từ máy tính + Nút khôi phục mặc định
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF38BDF8),
                                  side: const BorderSide(
                                    color: Color(0xFF475569),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _pickGifFromDevice,
                                icon: const Icon(
                                  Icons.gif_box_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  hasCustomGif
                                      ? 'Đổi GIF khác'
                                      : 'Chọn GIF từ máy',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            if (hasCustomGif) ...<Widget>[
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip:
                                    'Khôi phục hiệu ứng mặc định ($_gifFileName)',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF334155),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _resetToDefaultAnimation,
                                icon: const Icon(
                                  Icons.restart_alt_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trình phát ảnh GIF chuyên dụng giải mã trực tiếp toàn bộ các khung hình
/// (`ui.FrameInfo`) từ mảng `Uint8List` bằng `ui.instantiateImageCodec`.
///
/// Lợi ích vượt trội trên Flutter Web / Desktop:
/// 1. Đảm bảo 100% file GIF tải lên luôn chuyển động mượt mà qua từng frame
///    (không bao giờ bị đứng ở frame đầu như `Image.memory` mặc định trên Web).
/// 2. Ngay cả khi người dùng tải lên một file GIF chỉ có 1 frame (ảnh tĩnh),
///    widget vẫn tự động bổ sung hiệu ứng chuyển động nhẹ để phân biệt rõ
///    khi Main Thread bị đơ (Nút 1) và khi chạy mượt (Nút 2).
class _AnimatedGifMemoryPlayer extends StatefulWidget {
  const _AnimatedGifMemoryPlayer({
    super.key,
    required this.gifBytes,
  });

  final Uint8List gifBytes;

  @override
  State<_AnimatedGifMemoryPlayer> createState() =>
      _AnimatedGifMemoryPlayerState();
}

class _AnimatedGifMemoryPlayerState extends State<_AnimatedGifMemoryPlayer>
    with SingleTickerProviderStateMixin {
  final List<ui.Image> _frames = <ui.Image>[];
  final List<Duration> _durations = <Duration>[];
  int _currentFrameIndex = 0;
  bool _isDecoding = true;
  bool _decodeFailed = false;
  Timer? _frameTimer;

  /// Dự phòng trường hợp file người dùng tải lên thực chất chỉ có 1 frame tĩnh.
  late final AnimationController _singleFrameBounceController;

  @override
  void initState() {
    super.initState();
    _singleFrameBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _decodeAllGifFrames();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _singleFrameBounceController.dispose();
    for (final ui.Image img in _frames) {
      img.dispose();
    }
    super.dispose();
  }

  Future<void> _decodeAllGifFrames() async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(widget.gifBytes);
      final int count = codec.frameCount;

      for (int i = 0; i < count; i++) {
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        if (!mounted) {
          frameInfo.image.dispose();
          return;
        }
        _frames.add(frameInfo.image);
        // Nếu frame duration quá ngắn (<16ms) hoặc = 0, chuẩn hóa về 80ms (~12.5 fps chuẩn GIF)
        final int ms = frameInfo.duration.inMilliseconds;
        _durations.add(Duration(milliseconds: ms < 20 ? 80 : ms));
      }

      if (!mounted) return;
      setState(() {
        _isDecoding = false;
      });

      if (_frames.length > 1) {
        _scheduleNextFrame();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDecoding = false;
        _decodeFailed = true;
      });
    }
  }

  void _scheduleNextFrame() {
    if (!mounted || _frames.length <= 1) return;
    final Duration delay = _durations[_currentFrameIndex];
    _frameTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _currentFrameIndex = (_currentFrameIndex + 1) % _frames.length;
      });
      _scheduleNextFrame();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDecoding) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF38BDF8),
          ),
        ),
      );
    }

    if (_decodeFailed || _frames.isEmpty) {
      return Image.memory(
        widget.gifBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    // Nếu file GIF có nhiều frame (> 1): Vẽ liên tục từng frame đã giải mã
    if (_frames.length > 1) {
      return RawImage(
        image: _frames[_currentFrameIndex],
        fit: BoxFit.cover,
        width: 170,
        height: 170,
      );
    }

    // Nếu người dùng vô tình chọn ảnh chỉ có 1 frame duy nhất:
    // Tự động tạo chuyển động nhấp nhô mượt mà để vẫn thấy rõ đứng hình khi bấm Nút 1
    return AnimatedBuilder(
      animation: _singleFrameBounceController,
      builder: (BuildContext context, Widget? child) {
        final double scale = 0.92 + (_singleFrameBounceController.value * 0.12);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: RawImage(
        image: _frames.first,
        fit: BoxFit.cover,
        width: 170,
        height: 170,
      ),
    );
  }
}

/// Hiệu ứng Animation mặc định tự chạy mượt mà ngay khi mở ứng dụng
/// (khi người dùng chưa bấm chọn file GIF từ máy tính).
class _DefaultSmoothOrbitAnimation extends StatefulWidget {
  const _DefaultSmoothOrbitAnimation();

  @override
  State<_DefaultSmoothOrbitAnimation> createState() =>
      _DefaultSmoothOrbitAnimationState();
}

class _DefaultSmoothOrbitAnimationState
    extends State<_DefaultSmoothOrbitAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _OrbitGalaxyPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _OrbitGalaxyPainter extends CustomPainter {
  const _OrbitGalaxyPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width * 0.38;
    final double fullAngle = progress * 2 * math.pi;

    // 1. Vòng quỹ đạo ngoài xoay thuận chiều kim đồng hồ
    final Paint outerRingPaint = Paint()
      ..shader = const SweepGradient(
        colors: <Color>[
          Color(0xFF38BDF8),
          Color(0xFF818CF8),
          Color(0xFFF472B6),
          Color(0xFF38BDF8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      fullAngle,
      math.pi * 1.45,
      false,
      outerRingPaint,
    );

    // 2. Vòng quỹ đạo giữa xoay ngược chiều kim đồng hồ
    final double midRadius = maxRadius * 0.68;
    final Paint midRingPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: midRadius),
      -fullAngle * 1.5,
      math.pi * 1.1,
      false,
      midRingPaint,
    );

    // 3. Ba hạt vệ tinh phát sáng chuyển động quanh quỹ đạo
    for (int i = 0; i < 3; i++) {
      final double planetAngle = fullAngle + (i * 2 * math.pi / 3);
      final Offset planetPos = Offset(
        center.dx + maxRadius * math.cos(planetAngle),
        center.dy + maxRadius * math.sin(planetAngle),
      );
      canvas.drawCircle(
        planetPos,
        5.5,
        Paint()..color = Colors.white,
      );
    }

    // 4. Tâm nhịp thở (pulsing core) ở chính giữa
    final double pulse = (math.sin(fullAngle * 2) + 1) / 2;
    canvas.drawCircle(
      center,
      10 + pulse * 6,
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25 + 0.35 * pulse),
    );
    canvas.drawCircle(
      center,
      7,
      Paint()..color = const Color(0xFF38BDF8),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitGalaxyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
