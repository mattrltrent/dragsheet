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
      (ctx) => MySheetContent(action: () => controller.dismiss()),
      shrinkWrap: false,
      minScale: 0.8,
      maxScale: 1.0,
      minRadius: 8.0,
      maxRadius: 40.0,
      entranceDuration: Duration(milliseconds: 400),
      exitDuration: Duration(milliseconds: 400),
      gestureFadeDuration: Duration(milliseconds: 200),
      programmaticFadeDuration: Duration(milliseconds: 1200),
      effectDistance: 150.0,
    );
  }

  void _hideSheet() {
    controller.dismiss();
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
            ElevatedButton(onPressed: _hideSheet, child: Text("Hide Sheet")),
          ],
        ),
      ),
    );
  }
}

class MySheetContent extends StatelessWidget {
  const MySheetContent({super.key, required this.action});

  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.blue),
      child: Center(
        child: Column(
          children: [
            Text("hullo wurld", style: TextStyle(color: Colors.white, fontSize: 32)),

            TextButton(onPressed: action, child: Text("close")),
          ],
        ),
      ),
    );
  }
}
