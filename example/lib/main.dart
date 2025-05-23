import 'package:dragsheet/dragsheet.dart';
import 'package:example/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Demo());
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
  void initState() {
    super.initState();
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.removeListener(() => setState(() {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // linear gradient background orange ish ligher orange
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 255, 165, 0), Color.fromARGB(255, 255, 140, 0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed:
                    () => controller.show(
                      context,
                      (ctx) => DemoBottomSheet(onDismiss: controller.dismiss),
                      shrinkWrap: true,
                      maxRadius: 0,
                      bgOpacity: BgOpacity(color: Colors.black.withOpacity(0.5)),
                      onShow: () => HapticFeedback.lightImpact(),
                      onDismiss: () => HapticFeedback.lightImpact(),
                    ),
                child: Text("Show Sheet"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => controller.dismiss(), child: Text("Hide Sheet")),
              const SizedBox(height: 16),
              Text("Sheet is open: ${controller.isOpen}", style: TextStyle(fontSize: 18)),
            ],
          ),
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
