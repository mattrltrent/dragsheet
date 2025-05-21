import 'package:dragsheet/dragsheet.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "Example", theme: ThemeData(), debugShowCheckedModeBanner: false, home: Demo());
  }
}

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  final controller = DragSheetController();

  void _showSheet() {
    controller.show(
      context,
      (ctx) => Container(
        color: Colors.blue,
        child: const Center(child: Text("hullo wurld", style: TextStyle(color: Colors.white, fontSize: 32))),
      ),
      openRatio: 1,
      shrinkWrap: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _showSheet, child: Text("Show Sheet")),
            const SizedBox(height: 16),
            Text("Press multiple times for stacked sheets.\nEach new sheet dismisses previous ones."),
          ],
        ),
      ),
    );
  }
}
