class DailyManifest {
  final int id;
  final DateTime manifestDate;
  final String studentId;
  final int allocatedBusId;

  DailyManifest({
    required this.id,
    required this.manifestDate,
    required this.studentId,
    required this.allocatedBusId,
  });

  factory DailyManifest.fromJson(Map<String, dynamic> json) {
    return DailyManifest(
      id: json['id'] as int,
      manifestDate: DateTime.parse(json['manifest_date'] as String),
      studentId: json['student_id'] as String,
      allocatedBusId: json['allocated_bus_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manifest_date': manifestDate.toIso8601String().split('T')[0],
      'student_id': studentId,
      'allocated_bus_id': allocatedBusId,
    };
  }
}
