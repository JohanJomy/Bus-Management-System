class Student {
  final String id;
  final String fullName;
  final String email;
  final String? course;
  final int? semester;
  final int? boardingStopId;

  Student({
    required this.id,
    required this.fullName,
    required this.email,
    this.course,
    this.semester,
    this.boardingStopId,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      course: json['course'] as String?,
      semester: json['semester'] as int?,
      boardingStopId: json['boarding_stop_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'course': course,
      'semester': semester,
      'boarding_stop_id': boardingStopId,
    };
  }

  Student copyWith({
    String? id,
    String? fullName,
    String? email,
    String? course,
    int? semester,
    int? boardingStopId,
  }) {
    return Student(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      boardingStopId: boardingStopId ?? this.boardingStopId,
    );
  }
}
