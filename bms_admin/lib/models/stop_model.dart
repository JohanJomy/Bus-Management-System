class Stop {
  final int id;
  final String stopName;
  final double feeAmount;
  final String? arrivalTime;
  final int? actualBusId;
  final double? latitude;
  final double? longitude;

  Stop({
    required this.id,
    required this.stopName,
    required this.feeAmount,
    this.arrivalTime,
    this.actualBusId,
    this.latitude,
    this.longitude,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] as int,
      stopName: json['stop_name'] as String,
      feeAmount: (json['fee_amount'] as num).toDouble(),
      arrivalTime: json['arrival_time'] as String?,
      actualBusId: json['actual_bus'] as int?,
      latitude: json['lat'] as double?,
      longitude: json['long'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stop_name': stopName,
      'fee_amount': feeAmount,
      'arrival_time': arrivalTime,
      'actual_bus': actualBusId,
      'lat': latitude,
      'long': longitude,
    };
  }
}
