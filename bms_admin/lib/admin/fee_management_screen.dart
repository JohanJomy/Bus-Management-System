import 'package:flutter/material.dart';
import 'app_theme.dart';

const Color _primaryColor = Color(0xFF195DE6);

class FeeManagementScreen extends StatelessWidget {
  const FeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title + actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fees & Payments',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: onSurface(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage student transport fees, configure stop-wise charges, and monitor collection status.',
                        style: TextStyle(
                          fontSize: 14,
                          color: onSurfaceVariant(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        foregroundColor: _primaryColor,
                        side: BorderSide(
                          color: _primaryColor.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.upload_file_outlined, size: 20),
                      label: const Text(
                        'Export Report',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _primaryColor.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                      ),
                      label: const Text(
                        'Send Reminders',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Summary cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                final cardWidth = isNarrow
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: const _SummaryCard(
                        title: 'Total Collected',
                        value: '\$45,000',
                        deltaText: '+12.5%',
                        deltaColor: Colors.green,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: const _SummaryCard(
                        title: 'Pending Dues',
                        value: '\$12,500',
                        deltaText: '-5.2%',
                        deltaColor: Colors.orange,
                        icon: Icons.pending_actions_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Main content: left fee configuration, right payment history
            LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 950;

                final left = SizedBox(
                  width: isStacked
                      ? double.infinity
                      : constraints.maxWidth * 0.32,
                  child: const _FeeConfigurationCard(),
                );

                final right = SizedBox(
                  width: isStacked
                      ? double.infinity
                      : constraints.maxWidth * 0.64,
                  child: const _PaymentHistoryCard(),
                );

                if (isStacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [left, const SizedBox(height: 24), right],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [left, const SizedBox(width: 24), right],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String deltaText;
  final Color deltaColor;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.deltaText,
    required this.deltaColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark(context) ? 0.0 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: onSurfaceVariant(context),
                ),
              ),
              Icon(icon, color: deltaColor, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: onSurface(context),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                deltaText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: deltaColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'vs. previous month',
            style: TextStyle(fontSize: 11, color: onSurfaceVariant(context)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fee Configuration Card (left panel)
// ---------------------------------------------------------------------------

class _FeeConfigurationCard extends StatelessWidget {
  const _FeeConfigurationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark(context) ? 0.0 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: onSurface(context),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Edit All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildStopFeeItem(
                  context,
                  'Downtown Central',
                  'Monthly transport fee',
                  '\$120',
                ),
                const SizedBox(height: 16),
                _buildStopFeeItem(
                  context,
                  'North Suburb',
                  'Monthly transport fee',
                  '\$100',
                ),
                const SizedBox(height: 16),
                _buildStopFeeItem(
                  context,
                  'East Gate Terminus',
                  'Monthly transport fee',
                  '\$150',
                ),
                const SizedBox(height: 16),
                _buildStopFeeItem(
                  context,
                  'West River Plaza',
                  'Monthly transport fee',
                  '\$130',
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(
                      color: _primaryColor.withValues(alpha: 0.3),
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(
                    Icons.add_location_alt_outlined,
                    size: 18,
                    color: _primaryColor,
                  ),
                  label: const Text(
                    'Add New Stop Fee',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopFeeItem(
    BuildContext context,
    String stopName,
    String description,
    String amount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stopName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: onSurface(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: onSurfaceVariant(context)),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: onSurface(context),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: _primaryColor,
              ),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              splashRadius: 18,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Payment History Card (right panel)
// ---------------------------------------------------------------------------

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard();

  // Payment History Card build
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark(context) ? 0.0 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: onSurface(context),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          prefixIconColor: Colors.grey[500],
                          hintText: 'Search student...',
                          hintStyle: const TextStyle(fontSize: 12),
                          filled: true,
                          fillColor: inputFillColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: inputFillColor(context),
                      ),
                      onPressed: () {},
                      icon: Icon(
                        Icons.filter_list,
                        color: onSurfaceVariant(context),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Table
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark(context)
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF3F4F6),
                    ),
                    columnSpacing: 24,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 64,
                    columns: [
                      DataColumn(
                        label: Text(
                          'STUDENT NAME',
                          style: _headerStyle(context),
                        ),
                      ),
                      DataColumn(
                        label: Text('COURSE', style: _headerStyle(context)),
                      ),
                      DataColumn(
                        label: Text('AMOUNT', style: _headerStyle(context)),
                      ),
                      DataColumn(
                        label: Text('DATE', style: _headerStyle(context)),
                      ),
                      DataColumn(
                        label: Text('STATUS', style: _headerStyle(context)),
                      ),
                      DataColumn(label: SizedBox()),
                    ],
                    rows: [
                      _paymentRow(
                        context,
                        'RS',
                        const Color(0xFFE5EDFF),
                        const Color(0xFF1D4ED8),
                        'Rahul Sharma',
                        'BTech (CS)',
                        '\$120',
                        'Oct 12, 2023',
                        'Paid',
                        const Color(0xFF15803D),
                        const Color(0xFFD1FAE5),
                      ),
                      _paymentRow(
                        context,
                        'AP',
                        const Color(0xFFFFEDD5),
                        const Color(0xFFEA580C),
                        'Ananya Patel',
                        'MCA',
                        '\$100',
                        'Oct 14, 2023',
                        'Pending',
                        const Color(0xFFC2410C),
                        const Color(0xFFFFEDD5),
                      ),
                      _paymentRow(
                        context,
                        'VJ',
                        const Color(0xFFDBEAFE),
                        const Color(0xFF1D4ED8),
                        'Vikram Jha',
                        'BTech (ME)',
                        '\$120',
                        'Oct 15, 2023',
                        'Paid',
                        const Color(0xFF15803D),
                        const Color(0xFFD1FAE5),
                      ),
                      _paymentRow(
                        context,
                        'SM',
                        const Color(0xFFEDE9FE),
                        const Color(0xFF6D28D9),
                        'Sanya Malhotra',
                        'MTech',
                        '\$150',
                        'Oct 18, 2023',
                        'Pending',
                        const Color(0xFFC2410C),
                        const Color(0xFFFFEDD5),
                      ),
                      _paymentRow(
                        context,
                        'DS',
                        const Color(0xFFCCFBF1),
                        const Color(0xFF0F766E),
                        'Deepak Singh',
                        'BTech (CS)',
                        '\$120',
                        'Oct 20, 2023',
                        'Paid',
                        const Color(0xFF15803D),
                        const Color(0xFFD1FAE5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Pagination footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 5 of 248 records',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurfaceVariant(context),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle _headerStyle(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
  );

  static DataRow _paymentRow(
    BuildContext context,
    String initials,
    Color initialsColor,
    Color initialsTextColor,
    String studentName,
    String course,
    String amount,
    String date,
    String status,
    Color statusColor,
    Color statusBackground,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: initialsColor,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: initialsTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                studentName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onSurface(context),
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE0ECFF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              course,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: onSurface(context),
            ),
          ),
        ),
        DataCell(
          Text(
            date,
            style: TextStyle(
              fontSize: 11,
              color: onSurfaceVariant(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
