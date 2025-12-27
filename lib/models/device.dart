class Device {
  final String id;
  String macAddress;
  bool isInUse;
  String? employeeId;
  DateTime? usageStartTime;

  Device({
    required this.id,
    required this.macAddress,
    this.isInUse = false,
    this.employeeId,
    this.usageStartTime,
  });

  /// 檢查設備是否可以被領用
  bool canBeUsed() {
    return !isInUse;
  }

  /// 標記設備為已領用
  void markAsUsed(String empId) {
    isInUse = true;
    employeeId = empId;
    usageStartTime = DateTime.now();
  }

  /// 歸還設備
  void returnDevice() {
    isInUse = false;
    employeeId = null;
    usageStartTime = null;
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      macAddress: json['macAddress'] as String,
      isInUse: json['isInUse'] as bool? ?? false,
      employeeId: json['employeeId'] as String?,
      usageStartTime: json['usageStartTime'] != null
          ? DateTime.parse(json['usageStartTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'macAddress': macAddress,
      'isInUse': isInUse,
      'employeeId': employeeId,
      'usageStartTime': usageStartTime?.toIso8601String(),
    };
  }
}
