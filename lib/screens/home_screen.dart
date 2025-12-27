  import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import 'device_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final DeviceService deviceService;

  const HomeScreen({Key? key, required this.deviceService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _deletePassword = '80402907';
  late TextEditingController _macController;
  late DeviceService _deviceService;

  @override
  void initState() {
    super.initState();
    _macController = TextEditingController();
    _deviceService = widget.deviceService;
  }

  @override
  void dispose() {
    _macController.dispose();
    super.dispose();
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新增 MAC 設備'),
          content: SizedBox(
            width: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _macController,
                    decoration: InputDecoration(
                      labelText: 'MAC 地址',
                      hintText: '任何格式',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '格式不限，請輸入 MAC',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final mac = _macController.text.trim();
                if (mac.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('請輸入 MAC 地址')));
                  return;
                }
                final success = await _deviceService.addDevice(mac);
                _macController.clear();
                Navigator.pop(context);
                if (success) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已新增設備: $mac'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('新增設備失敗'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('新增'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Device> devices = _deviceService.getDevices();

    return Scaffold(
      appBar: AppBar(
  title: const Text('領用登記系統'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增設備',
            onPressed: _showAddDeviceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: '變更刪除密碼',
            onPressed: () async {
              final oldPwdController = TextEditingController();
              final newPwdController = TextEditingController();
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('變更刪除密碼'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: oldPwdController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '原始密碼'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPwdController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '新密碼'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (oldPwdController.text == _deletePassword && newPwdController.text.isNotEmpty) {
                          setState(() {
                            _deletePassword = newPwdController.text;
                          });
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('原始密碼錯誤或新密碼為空'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text('儲存'),
                    ),
                  ],
                ),
              );
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密碼已變更'), backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
      ),
      body: devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暫無設備',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _showAddDeviceDialog,
                    child: const Text('新增第一個設備'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) async {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = devices.removeAt(oldIndex);
                    devices.insert(newIndex, item);
                  });
                  // TODO: 若需永久儲存順序，請在此呼叫 storageService.saveDevices(devices)
                },
                children: [
                  for (int index = 0; index < devices.length; index++)
                    InkWell(
                      key: ValueKey(devices[index].id),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceDetailScreen(
                              device: devices[index],
                              deviceService: widget.deviceService,
                              onRefresh: () => setState(() {}),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              devices[index].isInUse ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: devices[index].isInUse ? Colors.orange : Colors.grey,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                devices[index].macAddress,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              devices[index].isInUse ? '已領用' : '未領用',
                              style: TextStyle(
                                fontSize: 18,
                                color: devices[index].isInUse ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (devices[index].isInUse) ...[
                              const SizedBox(width: 16),
                              Text(
                                devices[index].employeeId ?? '',
                                style: const TextStyle(fontSize: 16, color: Colors.orange),
                              ),
                            ],
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: '更改 MAC',
                              onPressed: () async {
                                final macController = TextEditingController(text: devices[index].macAddress);
                                final confirm = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('更改 MAC'),
                                    content: TextField(
                                      controller: macController,
                                      decoration: const InputDecoration(labelText: 'MAC 地址'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, null),
                                        child: const Text('取消'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, macController.text.trim()),
                                        child: const Text('儲存'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != null && confirm.isNotEmpty && confirm != devices[index].macAddress) {
                                  final success = await _deviceService.updateDeviceMac(devices[index].id, confirm);
                                  if (success) {
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('MAC 已更新為: $confirm'), backgroundColor: Colors.blue),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('MAC 更新失敗'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: '刪除設備',
                              onPressed: () async {
                                final pwdController = TextEditingController();
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('密碼驗證'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('請輸入密碼以刪除設備 ${devices[index].macAddress}'),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: pwdController,
                                          obscureText: true,
                                          decoration: const InputDecoration(labelText: '密碼'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () {
                                          if (pwdController.text == _deletePassword) {
                                            Navigator.pop(context, true);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('密碼錯誤，無法刪除'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                        child: const Text('確定刪除', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final success = await _deviceService.deleteDevice(devices[index].id);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? '已刪除設備: ${devices[index].macAddress}' : '刪除設備失敗'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      // 新增設備按鈕已移至 AppBar actions
    );
  }

}
