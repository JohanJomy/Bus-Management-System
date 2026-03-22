import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import '../services/fee_metrics_service.dart';

const Color _primaryColor = Color(0xFF195DE6);

class FeeManagementScreen extends StatelessWidget {
  const FeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    final stopsStream = client
        .from('stops')
        .stream(primaryKey: ['id'])
        .order('stop_name');
    final studentsStream = client
        .from('students')
        .stream(primaryKey: ['id'])
        .order('full_name');
    final paymentsStream = client
        .from('payments')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stopsStream,
      builder: (context, stopsSnapshot) {
        if (stopsSnapshot.hasError) {
          return _buildErrorState(context, 'Failed to load stops data.');
        }
        if (!stopsSnapshot.hasData) {
          return _buildLoadingState(context);
        }

        final stops = stopsSnapshot.data!;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: studentsStream,
          builder: (context, studentsSnapshot) {
            if (studentsSnapshot.hasError) {
              return _buildErrorState(context, 'Failed to load students data.');
            }
            if (!studentsSnapshot.hasData) {
              return _buildLoadingState(context);
            }

            final students = studentsSnapshot.data!;

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: paymentsStream,
              builder: (context, paymentsSnapshot) {
                if (paymentsSnapshot.hasError) {
                  return _buildErrorState(
                    context,
                    'Failed to load payments data.',
                  );
                }
                if (!paymentsSnapshot.hasData) {
                  return _buildLoadingState(context);
                }

                final payments = paymentsSnapshot.data!;
                final metricsData = FeeMetricsService.compute(
                  stops: stops,
                  students: students,
                  payments: payments,
                );
                final metrics = _FeeMetrics.fromSnapshot(metricsData);

                final studentsById = <String, Map<String, dynamic>>{};
                for (final student in students) {
                  final id = student['id']?.toString();
                  if (id != null && id.isNotEmpty) {
                    studentsById[id] = student;
                  }
                }

                return Container(
                  color: bgColor(context),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    'Live sync with database: stop fees, pending dues, and payment records update automatically.',
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
                                      color: _primaryColor.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.upload_file_outlined,
                                    size: 20,
                                  ),
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
                                    shadowColor: _primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
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
                                  child: _SummaryCard(
                                    title: 'Total Collected',
                                    value: _formatCurrency(
                                      metrics.totalCollected,
                                    ),
                                    deltaText: metrics.collectionDeltaText,
                                    deltaColor: metrics.collectionDeltaColor,
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _SummaryCard(
                                    title: 'Pending Dues',
                                    value: _formatCurrency(metrics.pendingDues),
                                    deltaText:
                                        '${metrics.unpaidStudents} unpaid students',
                                    deltaColor: metrics.unpaidStudents == 0
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFC2410C),
                                    icon: Icons.pending_actions_outlined,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isStacked = constraints.maxWidth < 950;

                            final left = SizedBox(
                              width: isStacked
                                  ? double.infinity
                                  : constraints.maxWidth * 0.32,
                              child: _FeeConfigurationCard(stops: stops),
                            );

                            final right = SizedBox(
                              width: isStacked
                                  ? double.infinity
                                  : constraints.maxWidth * 0.64,
                              child: _PaymentHistoryCard(
                                payments: payments,
                                studentsById: studentsById,
                              ),
                            );

                            if (isStacked) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  left,
                                  const SizedBox(height: 24),
                                  right,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                left,
                                const SizedBox(width: 24),
                                right,
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Text(message, style: TextStyle(color: onSurfaceVariant(context))),
    );
  }
}

class _FeeMetrics {
  final double totalCollected;
  final double pendingDues;
  final int unpaidStudents;
  final String collectionDeltaText;
  final Color collectionDeltaColor;

  const _FeeMetrics({
    required this.totalCollected,
    required this.pendingDues,
    required this.unpaidStudents,
    required this.collectionDeltaText,
    required this.collectionDeltaColor,
  });

  factory _FeeMetrics.fromSnapshot(FeeMetricsSnapshot snapshot) {
    final deltaPrefix = snapshot.collectionDeltaPercent >= 0 ? '+' : '';
    final deltaText =
        '$deltaPrefix${snapshot.collectionDeltaPercent.toStringAsFixed(1)}%';
    return _FeeMetrics(
      totalCollected: snapshot.totalCollected,
      pendingDues: snapshot.pendingAmount,
      unpaidStudents: snapshot.unpaidStudents,
      collectionDeltaText: deltaText,
      collectionDeltaColor: snapshot.collectionDeltaPercent >= 0
          ? const Color(0xFF15803D)
          : const Color(0xFFC2410C),
    );
  }
}

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
            'updates live from database',
            style: TextStyle(fontSize: 11, color: onSurfaceVariant(context)),
          ),
        ],
      ),
    );
  }
}

class _FeeConfigurationCard extends StatefulWidget {
  final List<Map<String, dynamic>> stops;

  const _FeeConfigurationCard({required this.stops});

  @override
  State<_FeeConfigurationCard> createState() => _FeeConfigurationCardState();
}

class _FeeConfigurationCardState extends State<_FeeConfigurationCard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredStops {
    if (_searchQuery.isEmpty) {
      return widget.stops;
    }
    final q = _searchQuery.toLowerCase();
    return widget.stops.where((stop) {
      final name = stop['stop_name']?.toString().toLowerCase() ?? '';
      return name.contains(q);
    }).toList();
  }

  Future<void> _showEditFeeDialog(Map<String, dynamic> stop) async {
    final stopName = stop['stop_name']?.toString() ?? 'Unknown Stop';
    final stopId = stop['id'];
    if (stopId is! int) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid stop ID. Cannot update fee.')),
      );
      return;
    }

    final currentFee = _asDouble(stop['fee_amount']);
    final controller = TextEditingController(
      text: currentFee.truncateToDouble() == currentFee
          ? currentFee.toStringAsFixed(0)
          : currentFee.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Fee - $stopName'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly fee amount',
              prefixText: '₹ ',
            ),
            validator: (value) {
              final parsed = double.tryParse(value?.trim() ?? '');
              if (parsed == null) {
                return 'Enter a valid amount';
              }
              if (parsed < 0) {
                return 'Amount cannot be negative';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final newAmount = double.parse(controller.text.trim());
              try {
                await Supabase.instance.client
                    .from('stops')
                    .update({'fee_amount': newAmount})
                    .eq('id', stopId);
                if (!mounted) {
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Updated fee for $stopName to ₹${newAmount.toStringAsFixed(0)}',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update fee: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStops = _filteredStops;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    Text(
                      '${filteredStops.length} stops',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onSurfaceVariant(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    prefixIconColor: Colors.grey[500],
                    hintText: 'Search stop by name...',
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: inputFillColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: filteredStops.isEmpty
                ? Center(
                    child: Text(
                      widget.stops.isEmpty
                          ? 'No stops found in database'
                          : 'No stops match your search',
                      style: TextStyle(color: onSurfaceVariant(context)),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < filteredStops.length; i++) ...[
                        _buildStopFeeItem(
                          context,
                          filteredStops[i],
                          'Monthly transport fee',
                          _formatCurrency(
                            _asDouble(filteredStops[i]['fee_amount']),
                          ),
                        ),
                        if (i != filteredStops.length - 1)
                          const SizedBox(height: 16),
                      ],
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
                        onPressed: null,
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
    Map<String, dynamic> stop,
    String description,
    String amount,
  ) {
    final stopName = stop['stop_name']?.toString() ?? 'Unknown Stop';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
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
                style: TextStyle(
                  fontSize: 11,
                  color: onSurfaceVariant(context),
                ),
              ),
            ],
          ),
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
              onPressed: () => _showEditFeeDialog(stop),
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

class _PaymentHistoryCard extends StatefulWidget {
  final List<Map<String, dynamic>> payments;
  final Map<String, Map<String, dynamic>> studentsById;

  const _PaymentHistoryCard({
    required this.payments,
    required this.studentsById,
  });

  @override
  State<_PaymentHistoryCard> createState() => _PaymentHistoryCardState();
}

class _PaymentHistoryCardState extends State<_PaymentHistoryCard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    final filteredRows = rows.where((row) {
      if (_searchQuery.isEmpty) {
        return true;
      }
      final q = _searchQuery.toLowerCase();
      return row.studentName.toLowerCase().contains(q) ||
          row.course.toLowerCase().contains(q);
    }).toList();

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
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim();
                          });
                        },
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

          LayoutBuilder(
            builder: (context, constraints) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No payment records found in database.',
                    style: TextStyle(color: onSurfaceVariant(context)),
                  ),
                );
              }

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
                      const DataColumn(label: SizedBox()),
                    ],
                    rows: filteredRows
                        .map((row) => _paymentRow(context, row))
                        .toList(),
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredRows.length} of ${rows.length} records',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurfaceVariant(context),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: null,
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
                      onPressed: null,
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

  List<_PaymentRowModel> _buildRows() {
    return widget.payments.map((payment) {
      final studentId = payment['student_id']?.toString() ?? '';
      final student = widget.studentsById[studentId];

      final fullName = student?['full_name']?.toString() ?? 'Unknown Student';
      final course = student?['course']?.toString() ?? 'N/A';
      final amountPaid = _asDouble(payment['amount_paid']);
      final status = payment['status'] == true;
      final createdAt = _parseDate(payment['created_at']);

      return _PaymentRowModel(
        studentId: studentId,
        studentName: fullName,
        course: course,
        amount: amountPaid,
        date: createdAt,
        isPaid: status,
      );
    }).toList();
  }

  static TextStyle _headerStyle(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
  );

  DataRow _paymentRow(BuildContext context, _PaymentRowModel row) {
    final avatarBg = _pickAvatarBg(row.studentId);
    final avatarFg = _pickAvatarFg(row.studentId);

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: avatarBg,
                child: Text(
                  _initials(row.studentName),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: avatarFg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                row.studentName,
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
              row.course,
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
            _formatCurrency(row.amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: onSurface(context),
            ),
          ),
        ),
        DataCell(
          Text(
            _formatDate(row.date),
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
              color: row.isPaid
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              row.isPaid ? 'PAID' : 'PENDING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: row.isPaid
                    ? const Color(0xFF15803D)
                    : const Color(0xFFC2410C),
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

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'NA';
    }
    if (parts.length == 1) {
      final one = parts.first;
      return one.length >= 2
          ? one.substring(0, 2).toUpperCase()
          : one.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  Color _pickAvatarBg(String key) {
    const palette = [
      Color(0xFFE5EDFF),
      Color(0xFFFFEDD5),
      Color(0xFFDBEAFE),
      Color(0xFFEDE9FE),
      Color(0xFFCCFBF1),
    ];
    if (key.isEmpty) {
      return palette.first;
    }
    return palette[key.codeUnitAt(0) % palette.length];
  }

  Color _pickAvatarFg(String key) {
    const palette = [
      Color(0xFF1D4ED8),
      Color(0xFFEA580C),
      Color(0xFF1D4ED8),
      Color(0xFF6D28D9),
      Color(0xFF0F766E),
    ];
    if (key.isEmpty) {
      return palette.first;
    }
    return palette[key.codeUnitAt(0) % palette.length];
  }
}

class _PaymentRowModel {
  final String studentId;
  final String studentName;
  final String course;
  final double amount;
  final DateTime? date;
  final bool isPaid;

  const _PaymentRowModel({
    required this.studentId,
    required this.studentName,
    required this.course,
    required this.amount,
    required this.date,
    required this.isPaid,
  });
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _parseDate(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw)?.toLocal();
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '--';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatCurrency(double amount) {
  final intAmount = amount.truncateToDouble() == amount;
  return intAmount
      ? '₹${amount.toStringAsFixed(0)}'
      : '₹${amount.toStringAsFixed(2)}';
}
