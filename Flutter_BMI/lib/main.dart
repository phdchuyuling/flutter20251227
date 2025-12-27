import 'package:flutter/material.dart';

void main() => runApp(const BMICalculator());

class BMICalculator extends StatelessWidget {
  const BMICalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const BMIScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BMIScreen extends StatefulWidget {
  const BMIScreen({super.key});

  @override
  State<BMIScreen> createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  String result = "";

  void calculateBMI() {
    final double height = double.tryParse(heightController.text) ?? 0;
    final double weight = double.tryParse(weightController.text) ?? 0;
    if (height > 0 && weight > 0) {
      final bmi = weight / ((height / 100) * (height / 100));
      setState(() {
        result = "你的 BMI 為：${bmi.toStringAsFixed(2)}";
      });
    } else {
      setState(() {
        result = "請輸入正確的身高與體重";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BMI 計算器")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "身高 (cm)"),
            ),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "體重 (kg)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: calculateBMI, child: const Text("計算")),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
