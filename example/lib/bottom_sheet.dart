import 'package:blur/blur.dart';
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
    const borderRadius = BorderRadius.all(Radius.circular(30));
    return Container(
      // padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom, top: 15),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          // border: Border.all(color: const Color.fromARGB(222, 255, 255, 255), width: 0.9),
          // shadow that's like apple new frosty design
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(5, 10), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              // Apple-style white top-left shadow
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.45), // strong white
                          Colors.white.withOpacity(0.15), // fade out
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 1.0],
                      ),
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ),
              // Existing shadowy top-left overlay (optional: you can remove or blend with above)
              // Positioned.fill(
              //   child: IgnorePointer(
              //     child: Container(
              //       decoration: BoxDecoration(
              //         gradient: LinearGradient(
              //           begin: Alignment.topLeft,
              //           end: Alignment.bottomRight,
              //           colors: [
              //             Colors.black.withOpacity(0.18), // shadow color
              //             Colors.transparent,
              //           ],
              //           stops: [0.0, 1.7],
              //         ),
              //         borderRadius: borderRadius,
              //       ),
              //     ),
              //   ),
              // ),
              // Blur background
              Positioned.fill(
                child: Blur(
                  blur: 20,
                  child: Container(color: const Color.fromARGB(171, 245, 245, 245).withOpacity(0.3)),
                ),
              ),
              // Overlay color
              Positioned.fill(
                child: Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),

                  color: const Color.fromARGB(35, 133, 133, 133),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      // Fancy Title
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
                      // Fancy Subtitle
                      Text(
                        "Create a new account",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Divider
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        height: 1,
                        color: Colors.black.withOpacity(0.07),
                      ),
                      const SizedBox(height: 8),
                      // Dummy ListView
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
      ),
    );
  }
}
