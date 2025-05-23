import 'package:flutter/material.dart';

class DemoBottomSheet extends StatefulWidget {
  const DemoBottomSheet({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<DemoBottomSheet> createState() => _DemoBottomSheetState();
}

class _DemoBottomSheetState extends State<DemoBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 57, 57, 57),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text("This is a demo bottom sheet"),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: widget.onDismiss, child: const Text("Close")),
        ],
      ),
    );
  }
}
