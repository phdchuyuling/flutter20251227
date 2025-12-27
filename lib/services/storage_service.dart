import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';
import '../models/usage_history.dart';

class StorageService {
  static const String _devicesKey = 'devices';
  static const String _historyKey = 'usage_history';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> saveDevices(List<Device> devices) async {
    try {
      final List<String> jsonList = devices.map((device) => jsonEncode(device.toJson())).toList();
      return await _prefs.setStringList(_devicesKey, jsonList);
    } catch (e) {
      print('Error saving devices: $e');
      return false;
    }
  }

  List<Device> getDevices() {
    try {
      final List<String>? jsonList = _prefs.getStringList(_devicesKey);
      if (jsonList == null) return [];
      return jsonList.map((json) => Device.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      print('Error loading devices: $e');
      return [];
    }
  }

  Future<bool> addDevice(Device device) async {
    try {
      final devices = getDevices();
      devices.add(device);
      return await saveDevices(devices);
    } catch (e) {
      print('Error adding device: $e');
      return false;
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    try {
      final devices = getDevices();
      devices.removeWhere((device) => device.id == deviceId);
      return await saveDevices(devices);
    } catch (e) {
      print('Error deleting device: $e');
      return false;
    }
  }

  Future<bool> updateDevice(Device device) async {
    try {
      final devices = getDevices();
      final index = devices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        devices[index] = device;
        return await saveDevices(devices);
      }
      return false;
    } catch (e) {
      print('Error updating device: $e');
      return false;
    }
  }

  Future<bool> saveHistory(List<UsageHistory> histories) async {
    try {
      final List<String> jsonList = histories.map((history) => jsonEncode(history.toJson())).toList();
      return await _prefs.setStringList(_historyKey, jsonList);
    } catch (e) {
      print('Error saving history: $e');
      return false;
    }
  }

  List<UsageHistory> getHistory() {
    try {
      final List<String>? jsonList = _prefs.getStringList(_historyKey);
      if (jsonList == null) return [];
      return jsonList.map((json) => UsageHistory.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  Future<bool> addHistory(UsageHistory history) async {
    try {
      final histories = getHistory();
      histories.add(history);
      return await saveHistory(histories);
    } catch (e) {
      print('Error adding history: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      await _prefs.remove(_devicesKey);
      await _prefs.remove(_historyKey);
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}