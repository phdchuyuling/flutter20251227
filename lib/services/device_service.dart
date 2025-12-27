import 'package:uuid/uuid.dart';
import '../models/device.dart';
import '../models/usage_history.dart';
import 'storage_service.dart';

class DeviceService {
  /// 更新設備 MAC
  Future<bool> updateDeviceMac(String deviceId, String newMac) async {
    final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex == -1) return false;
    _devices[deviceIndex].macAddress = newMac;
    return await storageService.updateDevice(_devices[deviceIndex]);
  }
  final StorageService storageService;
  late List<Device> _devices;
  late List<UsageHistory> _histories;

  DeviceService(this.storageService);

  Future<void> initialize() async {
    _devices = storageService.getDevices();
    _histories = storageService.getHistory();
  }

  List<Device> getDevices() => _devices;

  List<UsageHistory> getHistories() => _histories;

  /// 驗證員編編號格式（最多6個英文數字）
  bool validateEmployeeId(String empId) {
    final regex = RegExp(r'^[a-zA-Z0-9]{1,6}$');
    return regex.hasMatch(empId);
  }

  /// 驗證 MAC 地址格式（不限制字元）
  bool validateMacAddress(String mac) {
    return mac.isNotEmpty;
  }

  /// 新增設備
  Future<bool> addDevice(String macAddress) async {
    if (!validateMacAddress(macAddress)) {
      print('Invalid MAC address format');
      return false;
    }

    final device = Device(
      id: const Uuid().v4(),
      macAddress: macAddress,
    );

    _devices.add(device);
    return await storageService.saveDevices(_devices);
  }

  /// 刪除設備
  Future<bool> deleteDevice(String deviceId) async {
    _devices.removeWhere((device) => device.id == deviceId);
    return await storageService.saveDevices(_devices);
  }

  /// 領用設備（防呆模式：檢查是否已被領用、員編未持有設備）
  Future<bool> checkoutDevice(String deviceId, String employeeId) async {
    if (!validateEmployeeId(employeeId)) {
      print('Invalid employee ID format');
      return false;
    }
    // 檢查該員編已持有設備數量，最多2台
    final checkedOutCount = _devices.where((d) => d.isInUse && d.employeeId == employeeId).length;
    if (checkedOutCount >= 2) {
      print('Employee already has two devices checked out');
      return false;
    }
    final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex == -1) {
      print('Device not found');
      return false;
    }
    final device = _devices[deviceIndex];
    if (device.isInUse) {
      print('Device is already in use by employee: ${device.employeeId}');
      return false;
    }
    // 標記設備為已領用
    device.markAsUsed(employeeId);
    // 記錄使用歷史
    final history = UsageHistory(
      id: const Uuid().v4(),
      deviceId: deviceId,
      employeeId: employeeId,
      checkOutTime: DateTime.now(),
    );
    _devices[deviceIndex] = device;
    _histories.add(history);
    await storageService.updateDevice(device);
    await storageService.addHistory(history);
    return true;
  }

  /// 歸還設備
  Future<bool> returnDevice(String deviceId) async {
    final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex == -1) {
      print('Device not found');
      return false;
    }

    final device = _devices[deviceIndex];
    if (!device.isInUse) {
      print('Device is not in use');
      return false;
    }

    // 更新歷史記錄中對應的領用記錄
    final historyIndex = _histories.indexWhere(
      (h) => h.deviceId == deviceId && h.checkInTime == null,
    );

    if (historyIndex != -1) {
      _histories[historyIndex].checkInTime = DateTime.now();
      await storageService.saveHistory(_histories);
    }

    // 標記設備為未領用
    device.returnDevice();
    _devices[deviceIndex] = device;

    return await storageService.updateDevice(device);
  }

  /// 獲取設備的當前狀態
  Map<String, dynamic> getDeviceStatus(String deviceId) {
    final device = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => Device(id: '', macAddress: ''),
    );

    return {
      'id': device.id,
      'macAddress': device.macAddress,
      'isInUse': device.isInUse,
      'employeeId': device.employeeId,
      'usageStartTime': device.usageStartTime,
    };
  }

  /// 獲取設備的使用歷史
  List<UsageHistory> getDeviceHistory(String deviceId) {
    return _histories.where((h) => h.deviceId == deviceId).toList();
  }
}
