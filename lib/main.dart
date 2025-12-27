import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/device_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = StorageService();
  await storageService.initialize();
  
  final deviceService = DeviceService(storageService);
  await deviceService.initialize();
  
  runApp(MyApp(deviceService: deviceService));
}

class MyApp extends StatelessWidget {
  final DeviceService deviceService;
  
  const MyApp({super.key, required this.deviceService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAC 設備管理系統',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(deviceService: deviceService),
      debugShowCheckedModeBanner: false,
    );
  }
}

