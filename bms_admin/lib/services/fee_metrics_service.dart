class FeeMetricsSnapshot {
  final double totalCollected;
  final double pendingAmount;
  final int unpaidStudents;
  final double collectionDeltaPercent;

  const FeeMetricsSnapshot({
    required this.totalCollected,
    required this.pendingAmount,
    required this.unpaidStudents,
    required this.collectionDeltaPercent,
  });
}

class FeeMetricsService {
  const FeeMetricsService._();

  static FeeMetricsSnapshot compute({
    required List<Map<String, dynamic>> stops,
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> payments,
  }) {
    final stopFeeById = <int, double>{};
    for (final stop in stops) {
      final stopId = stop['id'];
      if (stopId is int) {
        stopFeeById[stopId] = _asDouble(stop['fee_amount']);
      }
    }

    final paidByStudentSemester = <String, double>{};
    double totalCollected = 0;
    double currentMonthCollected = 0;
    double previousMonthCollected = 0;

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);

    for (final payment in payments) {
      if (payment['status'] != true) {
        continue;
      }

      final amount = _asDouble(payment['amount_paid']);
      totalCollected += amount;

      final studentId = payment['student_id']?.toString();
      final paymentSemester = _asInt(payment['semester']);
      if (studentId != null &&
          studentId.isNotEmpty &&
          paymentSemester != null) {
        final key = '$studentId|$paymentSemester';
        paidByStudentSemester[key] = (paidByStudentSemester[key] ?? 0) + amount;
      }

      final paymentDate = _parseDate(payment['created_at']);
      if (paymentDate != null) {
        if (!paymentDate.isBefore(currentMonthStart) &&
            paymentDate.isBefore(nextMonthStart)) {
          currentMonthCollected += amount;
        }
        if (!paymentDate.isBefore(previousMonthStart) &&
            paymentDate.isBefore(currentMonthStart)) {
          previousMonthCollected += amount;
        }
      }
    }

    double pendingAmount = 0;
    int unpaidStudents = 0;

    for (final student in students) {
      final stopId = student['boarding_stop_id'];
      final studentId = student['id']?.toString();
      final studentSemester = _asInt(student['semester']);
      if (stopId is! int ||
          studentId == null ||
          studentId.isEmpty ||
          studentSemester == null) {
        continue;
      }

      final expectedFee = stopFeeById[stopId] ?? 0;
      final key = '$studentId|$studentSemester';
      final paidAmount = paidByStudentSemester[key] ?? 0;
      final remaining = expectedFee - paidAmount;

      if (remaining > 0) {
        pendingAmount += remaining;
        unpaidStudents += 1;
      }
    }

    final deltaPercent = previousMonthCollected == 0
        ? (currentMonthCollected > 0 ? 100.0 : 0.0)
        : ((currentMonthCollected - previousMonthCollected) /
                  previousMonthCollected) *
              100;

    return FeeMetricsSnapshot(
      totalCollected: totalCollected,
      pendingAmount: pendingAmount,
      unpaidStudents: unpaidStudents,
      collectionDeltaPercent: deltaPercent,
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _parseDate(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw)?.toLocal();
}
