class Bus {
  final int id;
  final int busNumber;
  final int totalCapacity;

  Bus({
    required this.id,
    required this.busNumber,
    required this.totalCapacity,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as int,
      busNumber: json['bus_number'] as int,
      totalCapacity: json['total_capacity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_number': busNumber,
      'total_capacity': totalCapacity,
    };
  }
}
