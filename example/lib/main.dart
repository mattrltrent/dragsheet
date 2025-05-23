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
      onShow: () => print('Sheet shown!'),
      onDismiss: () => print('Sheet dismissed!'),
      // minScale: 0.8,
      // bgOpacity: BgOpacity(color: Colors.green, opacity: 0.5),
      // maxScale: 1.0,
      // minRadius: 0.0,
      // maxRadius: 20.0,
      // entranceDuration: Duration(milliseconds: 400),
      // exitDuration: Duration(milliseconds: 400),
      // gestureFadeDuration: Duration(milliseconds: 200),
      // programmaticFadeDuration: Duration(milliseconds: 1200),
      // effectDistance: 150.0,
      // swipeVelocityMultiplier: 3.5,
      // swipeAccelerationThreshold: 2500, // try lowering for easier boost
      // swipeAccelerationMultiplier: 7.0,
      // swipeMinVelocity: 2000.0,
      // swipeMaxVelocity: 6000.0,
      // swipeFriction: 0.07,
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
