import 'dart:math';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isMonthly = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 28),
            _buildMetricCards(context),
            const SizedBox(height: 24),
            _buildChartsRow(context),
            const SizedBox(height: 24),
            _buildRecentReports(context),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: onSurface(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Generate and analyze system performance reports.',
                style: TextStyle(
                  fontSize: 14,
                  color: onSurfaceVariant(context),
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text(
            'Download All',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: borderColor(context)),
            foregroundColor: onSurface(context),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Generate Custom Report',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF195DE6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ── Metric cards ───────────────────────────────────────────────────────────
  Widget _buildMetricCards(BuildContext context) {
    final metrics = [
      _Metric(
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFF22C55E),
        delta: '+12%',
        deltaPositive: true,
        label: 'Total Revenue',
        value: '\$45,200',
      ),
      _Metric(
        icon: Icons.people_alt_outlined,
        iconColor: const Color(0xFF3B82F6),
        delta: '-5%',
        deltaPositive: false,
        label: 'Avg. Occupancy',
        value: '78%',
      ),
      _Metric(
        icon: Icons.local_gas_station_outlined,
        iconColor: const Color(0xFFEF4444),
        delta: '-2%',
        deltaPositive: false,
        label: 'Fuel Consumption',
        value: '1,240L',
      ),
      _Metric(
        icon: Icons.access_time_outlined,
        iconColor: const Color(0xFFA855F7),
        delta: '+3%',
        deltaPositive: true,
        label: 'On-time Performance',
        value: '94%',
      ),
    ];

    return Row(
      children: metrics
          .map(
            (m) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: metrics.indexOf(m) < metrics.length - 1 ? 16 : 0,
                ),
                child: _MetricCard(metric: m),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Charts row ─────────────────────────────────────────────────────────────
  Widget _buildChartsRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _buildBarChartCard(context)),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: _buildDonutCard(context)),
      ],
    );
  }

  Widget _buildBarChartCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Monthly Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: onSurface(context),
                ),
              ),
              const Spacer(),
              _ToggleButton(
                label: 'Monthly',
                active: _isMonthly,
                onTap: () => setState(() => _isMonthly = true),
              ),
              const SizedBox(width: 4),
              _ToggleButton(
                label: 'Weekly',
                active: !_isMonthly,
                onTap: () => setState(() => _isMonthly = false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _BarChart(
              values: const [65, 72, 80, 100, 70, 82, 68],
              labels: const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL'],
              highlightIndex: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Efficiency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: onSurface(context),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _DonutPainter(
                      progress: 0.75,
                      trackColor: isDark(context)
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '75%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: onSurface(context),
                        ),
                      ),
                      Text(
                        'TARGET',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          color: onSurfaceVariant(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _routeLegendRow(
            context,
            const Color(0xFF195DE6),
            'Downtown Route',
            '88%',
          ),
          const SizedBox(height: 10),
          _routeLegendRow(
            context,
            const Color(0xFF93C5FD),
            'Airport Express',
            '62%',
          ),
        ],
      ),
    );
  }

  Widget _routeLegendRow(
    BuildContext context,
    Color dot,
    String label,
    String pct,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: onSurfaceVariant(context)),
          ),
        ),
        Text(
          pct,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: onSurface(context),
          ),
        ),
      ],
    );
  }

  // ── Recent Reports table ───────────────────────────────────────────────────
  Widget _buildRecentReports(BuildContext context) {
    final reports = [
      _Report(
        iconColor: const Color(0xFFEF4444),
        name: 'Fuel_Efficiency_August_2023',
        category: 'Fleet Performance',
        date: 'Sep 01, 2023',
        format: 'PDF',
        formatColor: const Color(0xFFEF4444),
      ),
      _Report(
        iconColor: const Color(0xFF22C55E),
        name: 'Quarterly_Revenue_Q3',
        category: 'Financial',
        date: 'Aug 28, 2023',
        format: 'EXCEL',
        formatColor: const Color(0xFF16A34A),
      ),
      _Report(
        iconColor: const Color(0xFFEF4444),
        name: 'Incident_Log_Weekly_W34',
        category: 'Operations',
        date: 'Aug 25, 2023',
        format: 'PDF',
        formatColor: const Color(0xFFEF4444),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onSurface(context),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF195DE6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Column headers
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor(context))),
              color: isDark(context)
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF8FAFC),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _colHeader(context, 'REPORT NAME', flex: 4),
                _colHeader(context, 'CATEGORY', flex: 3),
                _colHeader(context, 'GENERATED DATE', flex: 3),
                _colHeader(context, 'FORMAT', flex: 2),
                _colHeader(context, 'ACTIONS', flex: 1, align: TextAlign.right),
              ],
            ),
          ),
          // Rows
          ...reports.map((r) => _buildReportRow(context, r)),
        ],
      ),
    );
  }

  Widget _colHeader(
    BuildContext context,
    String text, {
    int flex = 1,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: onSurfaceVariant(context),
        ),
      ),
    );
  }

  Widget _buildReportRow(BuildContext context, _Report r) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor(context))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(Icons.description_outlined, color: r.iconColor, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    r.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: onSurface(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Category
          Expanded(
            flex: 3,
            child: Text(
              r.category,
              style: TextStyle(fontSize: 13, color: onSurfaceVariant(context)),
            ),
          ),
          // Date
          Expanded(
            flex: 3,
            child: Text(
              r.date,
              style: TextStyle(fontSize: 13, color: onSurfaceVariant(context)),
            ),
          ),
          // Format badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: r.formatColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              constraints: const BoxConstraints(maxWidth: 60),
              child: Text(
                r.format,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: r.formatColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Download
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.download_outlined,
                    size: 18,
                    color: onSurfaceVariant(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle button widget ──────────────────────────────────────────────────────
class _ToggleButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? (isDark(context)
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? onSurface(context) : onSurfaceVariant(context),
          ),
        ),
      ),
    );
  }
}

// ── Bar chart painter ─────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final int highlightIndex;

  const _BarChart({
    required this.values,
    required this.labels,
    required this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(
        values: values,
        labels: labels,
        highlightIndex: highlightIndex,
        barColor: isDark(context)
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFF195DE6),
        labelColor: isDark(context)
            ? const Color(0xFF64748B)
            : const Color(0xFF94A3B8),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final int highlightIndex;
  final Color barColor;
  final Color highlightColor;
  final Color labelColor;

  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.highlightIndex,
    required this.barColor,
    required this.highlightColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.reduce(max);
    const labelHeight = 20.0;
    final chartHeight = size.height - labelHeight - 8;
    final barWidth = size.width / values.length;
    const barPad = 12.0;

    final normalPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;

    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < values.length; i++) {
      final barH = (values[i] / maxVal) * chartHeight;
      final left = i * barWidth + barPad;
      final right = (i + 1) * barWidth - barPad;
      final top = chartHeight - barH;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, chartHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        i == highlightIndex ? highlightPaint : normalPaint,
      );

      // Label
      labelPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(fontSize: 11, color: labelColor),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          left + (right - left) / 2 - labelPainter.width / 2,
          chartHeight + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      oldDelegate.barColor != barColor ||
      oldDelegate.highlightColor != highlightColor;
}

// ── Donut chart painter ───────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double progress;
  final Color trackColor;

  const _DonutPainter({required this.progress, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF195DE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track (full circle)
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ── Data models ───────────────────────────────────────────────────────────────
class _Metric {
  final IconData icon;
  final Color iconColor;
  final String delta;
  final bool deltaPositive;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.iconColor,
    required this.delta,
    required this.deltaPositive,
    required this.label,
    required this.value,
  });
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: metric.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(metric.icon, color: metric.iconColor, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (metric.deltaPositive
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  metric.delta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: metric.deltaPositive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            metric.label,
            style: TextStyle(fontSize: 12, color: onSurfaceVariant(context)),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: onSurface(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Report {
  final Color iconColor;
  final String name;
  final String category;
  final String date;
  final String format;
  final Color formatColor;

  const _Report({
    required this.iconColor,
    required this.name,
    required this.category,
    required this.date,
    required this.format,
    required this.formatColor,
  });
}
