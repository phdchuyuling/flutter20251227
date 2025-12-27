class UsageHistory {
  final String id;
  final String deviceId;
  final String employeeId;
  final DateTime checkOutTime;
  DateTime? checkInTime;

  UsageHistory({
    required this.id,
    required this.deviceId,
    required this.employeeId,
    required this.checkOutTime,
    this.checkInTime,
  });

  /// 計算使用時長
  Duration? getUsageDuration() {
    if (checkInTime == null) return null;
    return checkInTime!.difference(checkOutTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'employeeId': employeeId,
      'checkOutTime': checkOutTime.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
    };
  }

  factory UsageHistory.fromJson(Map<String, dynamic> json) {
    return UsageHistory(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      employeeId: json['employeeId'] as String,
      checkOutTime: DateTime.parse(json['checkOutTime'] as String),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
    );
  }
}
