import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/computation_models.dart';

/// Card hiển thị kết quả chi tiết của lần chạy gần nhất và lịch sử đối chiếu.
class ComputationResultCard extends StatelessWidget {
  const ComputationResultCard({
    super.key,
    required this.latestResult,
    required this.history,
    required this.errorMessage,
    required this.onClearHistory,
  });

  final ComputationResult? latestResult;
  final List<ComputationResult> history;
  final String? errorMessage;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.analytics_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kết quả & Lịch sử chạy',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (history.isNotEmpty)
                  TextButton.icon(
                    onPressed: onClearHistory,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Xóa lịch sử'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (errorMessage != null) ...<Widget>[
              _buildErrorBanner(errorMessage!),
              const SizedBox(height: 12),
            ],
            if (latestResult == null && errorMessage == null)
              _buildEmptyState()
            else if (latestResult != null) ...<Widget>[
              _buildLatestResultHighlight(latestResult!),
              if (history.length > 1) ...<Widget>[
                const SizedBox(height: 16),
                const Text(
                  'Lịch sử so sánh các lần chạy gần đây:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                ...history
                    .skip(1)
                    .take(4)
                    .map(
                      (ComputationResult item) => _buildHistoryRow(item),
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.touch_app_outlined,
            size: 32,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 8),
          Text(
            'Chưa có dữ liệu chạy thử nghiệm',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy bấm Nút 1 (Main Thread) hoặc Nút 2 (Hàm compute) ở trên để quan sát sự khác biệt.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.dangerColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Đã bắt giữ ngoại lệ an toàn (Exception Handled)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.dangerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestResultHighlight(ComputationResult result) {
    final bool isMainThread = result.executionMode == ExecutionMode.mainThread;
    final Color accentColor =
        isMainThread ? AppTheme.dangerColor : AppTheme.successColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.executionMode.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMainThread
                      ? 'Hoàn thành trên Main Thread (Giao diện bị đứng)'
                      : 'Hoàn thành trên Worker Isolate (Giao diện mượt)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.summaryTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.summaryDetail,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          _buildMetricChip(
            icon: Icons.timer_outlined,
            label: 'Thời gian xử lý: ${result.durationMs} ms',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(ComputationResult item) {
    final bool isMain = item.executionMode == ExecutionMode.mainThread;
    final Color badgeColor =
        isMain ? AppTheme.dangerColor : AppTheme.successColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isMain ? Icons.block_rounded : Icons.bolt_rounded,
              size: 16,
              color: badgeColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.executionMode.label} • ${item.summaryTitle}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.durationMs} ms',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
