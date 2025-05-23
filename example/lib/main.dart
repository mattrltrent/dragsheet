import 'package:dragsheet/dragsheet.dart';
import 'package:example/demo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

/// The main application widget.
class MyApp extends StatelessWidget {
  /// Creates an instance of the main application widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Demo());
  }
}

/// A demonstration widget showcasing the DragSheet functionality.
class Demo extends StatefulWidget {
  /// Creates an instance of the demo widget.
  const Demo({super.key});

  @override
  State<Demo> createState() => _DemoState();
}

/// The state for the [Demo] widget.
class _DemoState extends State<Demo> {
  /// Controller to manage the state of the drag sheet.
  final controller = DragSheetController();

  @override
  void initState() {
    super.initState();
    // Listen to controller changes to rebuild the UI, e.g., to update text based on [controller.isOpen].
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Clean up the listener when the widget is disposed.
    controller.removeListener(() => setState(() {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Sheet is open: ${controller.isOpen}", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Normal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () => controller.show(
                              context,
                              (ctx) => DemoSheet(onDismiss: controller.dismiss, isFullScreen: true),
                              maxRadius: 20,
                              bgOpacity: BgOpacity(color: Colors.black.withOpacity(0.5)),
                              onShow: () => HapticFeedback.lightImpact(),
                              onDismiss: () => HapticFeedback.lightImpact(),
                            ),
                        child: const Text("Show"),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("ShrinkWrapped", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () => controller.show(
                              context,
                              (ctx) => DemoSheet(onDismiss: controller.dismiss, isFullScreen: false),
                              shrinkWrap: true,
                              maxRadius: 0,
                              bgOpacity: BgOpacity(color: Colors.black.withOpacity(0.5)),
                              onShow: () => HapticFeedback.lightImpact(),
                              onDismiss: () => HapticFeedback.lightImpact(),
                            ),
                        child: const Text("Show"),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
