import 'package:blur/blur.dart';
import 'package:flutter/material.dart';

/// A demonstration sheet widget that can be displayed within a [DragSheet].
///
/// This widget showcases a sample UI with various elements, and its appearance
/// can adapt based on whether it's intended to be full-screen or a partial sheet.
class DemoSheet extends StatefulWidget {
  /// Creates an instance of [DemoSheet].
  ///
  /// [onDismiss] is a callback that should be invoked when the sheet requests dismissal.
  /// [isFullScreen] determines if the sheet should adapt its layout for a full-screen presentation.
  const DemoSheet({super.key, required this.onDismiss, this.isFullScreen = false});

  /// Callback invoked when the sheet requests to be dismissed,
  /// for example, by tapping a close button.
  final VoidCallback onDismiss;

  /// If `true`, the sheet adjusts its layout for a full-screen appearance,
  /// such as removing rounded corners and adding safe area padding.
  /// If `false`, it assumes a more modal-like appearance with rounded corners.
  final bool isFullScreen;

  @override
  State<DemoSheet> createState() => _DemoSheetState();
}

class _DemoSheetState extends State<DemoSheet> {
  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = widget.isFullScreen ? BorderRadius.zero : const BorderRadius.all(Radius.circular(30));

    return Container(
      width: double.infinity,
      height: widget.isFullScreen ? double.infinity : MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow:
            widget.isFullScreen
                ? null
                : [
                  BoxShadow(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(5, 10),
                  ),
                ],
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white.withOpacity(0.45), Colors.white.withOpacity(0.15), Colors.transparent],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                    borderRadius: effectiveBorderRadius,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Blur(blur: 20, child: Container(color: const Color.fromARGB(171, 245, 245, 245).withOpacity(0.3))),
            ),
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.only(
                  top: widget.isFullScreen ? MediaQuery.of(context).padding.top : 0,
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                color: const Color.fromARGB(35, 133, 133, 133),
                child: Column(
                  children: [
                    if (!widget.isFullScreen) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 3,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 230, 229, 229),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 4.0),
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.black.withOpacity(0.7), size: 28),
                            onPressed: widget.onDismiss,
                          ),
                        ),
                      ),
                    ],
                    const Text(
                      "Sign up",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Create a new account",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      height: 1,
                      color: Colors.black.withOpacity(0.07),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: 10,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder:
                            (context, index) => Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.blueGrey[300]),
                                  const SizedBox(width: 12),
                                  Text(
                                    "List item ${index + 1}",
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
