import 'package:dragsheet/dragsheet.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            controller.show(
              context,
              (ctx) => Container(
                color: Colors.blue,
                child: const Center(child: Text("hullo wurld", style: TextStyle(color: Colors.white, fontSize: 32))),
              ),
            );
            // To close programmatically: controller.hide();
            // To check if shown: controller.isSheetShown;
          },
          child: Text("Show Sheet"),
        ),
      ),
    );
  }
}
