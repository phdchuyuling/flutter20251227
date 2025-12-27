import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';
import '../services/device_service.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  final DeviceService deviceService;
  final VoidCallback onRefresh;

  const DeviceDetailScreen({
    Key? key,
    required this.device,
    required this.deviceService,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  DateTime? _selectedDate;
  Widget _buildActionButton() {
    if (!_currentDevice.isInUse) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: _employeeIdController,
              decoration: const InputDecoration(
                labelText: '員工編號',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
              maxLength: 6,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final empId = _employeeIdController.text.trim();
              if (empId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請輸入員工編號')),
                );
                return;
              }
              if (!widget.deviceService.validateEmployeeId(empId)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('員編編號格式錯誤（最多6個英文數字）'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final success = await widget.deviceService.checkoutDevice(
                _currentDevice.id,
                empId,
              );
              if (success) {
                final updatedDevices = widget.deviceService.getDevices();
                _currentDevice = updatedDevices.firstWhere((d) => d.id == _currentDevice.id);
                setState(() {});
                widget.onRefresh();
                _employeeIdController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$empId 已領用此設備'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('設備已被其他人領用或系統錯誤'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('領用'),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: 90,
        height: 36,
        child: ElevatedButton(
          onPressed: () async {
            final success = await widget.deviceService.returnDevice(_currentDevice.id);
            if (success) {
              final updatedDevices = widget.deviceService.getDevices();
              _currentDevice = updatedDevices.firstWhere((d) => d.id == _currentDevice.id);
              setState(() {});
              widget.onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_currentDevice.macAddress} 已成功歸還'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('歸還失敗'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('歸還'),
        ),
      );
    }
  }

  late TextEditingController _employeeIdController;
  late Device _currentDevice;

  @override
  void initState() {
    super.initState();
    _employeeIdController = TextEditingController();
    _currentDevice = widget.device;
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    var usageHistory = widget.deviceService.getDeviceHistory(_currentDevice.id);
    // 過濾日期
    if (_selectedDate != null) {
      usageHistory = usageHistory.where((h) =>
        h.checkOutTime.year == _selectedDate!.year &&
        h.checkOutTime.month == _selectedDate!.month &&
        h.checkOutTime.day == _selectedDate!.day
      ).toList();
    }
    // 依 checkOutTime 由新到舊排序
    usageHistory.sort((a, b) => b.checkOutTime.compareTo(a.checkOutTime));

    return Scaffold(
      appBar: AppBar(title: const Text('設備詳情'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 設備信息卡片
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '設備信息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _buildActionButton(),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'MAC 地址: ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Expanded(child: Text(_currentDevice.macAddress)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          '設備 ID: ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Expanded(
                          child: Text(
                            _currentDevice.id,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 使用狀態卡片
            Card(
              elevation: 2,
              color: _currentDevice.isInUse
                  ? Colors.orange[50]
                  : Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '使用狀態',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _currentDevice.isInUse
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _currentDevice.isInUse
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentDevice.isInUse ? '已領用' : '未領用',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _currentDevice.isInUse
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (_currentDevice.isInUse) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            '領用人員編: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              _currentDevice.employeeId ?? '未知',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            '領用時間: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              _currentDevice.usageStartTime != null
                                  ? DateFormat(
                                      'yyyy-MM-dd HH:mm:ss',
                                    ).format(_currentDevice.usageStartTime!)
                                  : '未知',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 使用歷史
            Row(
              children: [
                const Text(
                  '使用歷史',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_selectedDate == null
                      ? '選擇日期'
                      : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: '清除日期',
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (usageHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    '暫無使用歷史',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: usageHistory.length,
                itemBuilder: (context, index) {
                  final history = usageHistory[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '員編: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(history.employeeId),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text(
                                '領用時間: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                DateFormat(
                                  'yyyy-MM-dd HH:mm:ss',
                                ).format(history.checkOutTime),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text(
                                '歸還時間: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                history.checkInTime != null
                                    ? DateFormat(
                                        'yyyy-MM-dd HH:mm:ss',
                                      ).format(history.checkInTime!)
                                    : '未歸還',
                              ),
                            ],
                          ),
                          if (history.getUsageDuration() != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  '使用時長: ',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  _formatDuration(history.getUsageDuration()!),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$hours小時 $minutes分鐘 $seconds秒';
  }
}
