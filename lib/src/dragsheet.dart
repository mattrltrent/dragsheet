import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:blur/blur.dart';

class DragSheetController extends ChangeNotifier {
  void show(BuildContext context, WidgetBuilder builder, {double openRatio = 1.0, bool shrinkWrap = false}) {
    final blurController = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 300),
    )..forward();

    late OverlayEntry entry;
    bool removed = false;
    bool _isSheetVisible = true;

    void removeBlur() {
      if (removed) return;
      removed = true;
      entry.remove();
      blurController.dispose();
    }

    entry = OverlayEntry(
      builder:
          (ctx) => Stack(
            children: [
              if (_isSheetVisible)
                Positioned.fill(child: AbsorbPointer(absorbing: true, child: Container(color: Colors.transparent))),
              DragSheet(
                builder: builder,
                openRatio: openRatio,
                shrinkWrap: shrinkWrap,
                onStartDismiss: () {
                  if (!_isSheetVisible) return;
                  _isSheetVisible = false;
                  entry.markNeedsBuild();
                },
                onDismissed: () {
                  removeBlur(); // <--- Use the guard here
                },
              ),
            ],
          ),
    );
    Overlay.of(context).insert(entry);
  }
}

class DragSheet extends StatefulWidget {
  final double openRatio;
  final bool shrinkWrap;
  final WidgetBuilder builder;
  final VoidCallback? onDismissed;
  final VoidCallback? onStartDismiss; // <-- Add this

  const DragSheet({
    super.key,
    required this.builder,
    this.openRatio = 1.0,
    this.shrinkWrap = false,
    this.onDismissed,
    this.onStartDismiss, // <-- Add this
  });

  @override
  DragSheetState createState() => DragSheetState();
}

class DragSheetState extends State<DragSheet> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late AnimationController _blurCtrl;
  double _blurAnim = 1.0;
  Offset _position = Offset(0, 1);
  bool _isOpened = false;
  bool _isSheetVisible = true;
  bool _isDismissing = false; // Track if we're flying out

  double get openY => 1 - widget.openRatio;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)..value = _position.dy;
    _blurCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400), value: 1.0);
    _blurCtrl.addListener(() {
      setState(() {
        _blurAnim = _blurCtrl.value;
      });
    });
    _showSheet();
  }

  void _showSheet() {
    setState(() {
      _position = Offset(0, 1);
      _isOpened = false; // <-- Reset on show
    });
    final spring = SpringDescription(mass: 1, stiffness: 500, damping: 50);
    final simY = SpringSimulation(spring, _position.dy, openY, 0.0);
    _ctrl.value = _position.dy;
    final future = _ctrl.animateWith(simY);
    _ctrl.addListener(() {
      if (mounted) {
        setState(() {
          _position = Offset(_position.dx, _ctrl.value);
        });
      }
    });
    future.whenComplete(() {
      if (mounted) setState(() => _isOpened = true);
    });
  }

  void _hideSheet({Offset? velocity}) {
    final dx = velocity?.dx ?? 0;
    final dy = velocity?.dy ?? 0;

    Offset? direction;
    if (_position.dx < -0.3) {
      direction = Offset(-1, 0);
    } else if (_position.dx > 0.3) {
      direction = Offset(1, 0);
    } else if (_position.dy < openY - 0.1) {
      direction = Offset(0, -1);
    } else if (_position.dy > openY + 0.3) {
      direction = Offset(0, 1);
    }

    if (direction != null) {
      widget.onStartDismiss?.call();
      _isDismissing = true;
      _blurCtrl.animateTo(0.0, duration: const Duration(milliseconds: 400));

      final target = Offset(_position.dx + direction.dx * 2.0, _position.dy + direction.dy * 2.0);
      final ctrl = AnimationController.unbounded(vsync: this);
      ctrl.value = 0.0;
      final simX = SpringSimulation(
        SpringDescription(mass: 1, stiffness: 200, damping: 20),
        _position.dx,
        target.dx,
        dx,
      );
      final simY = SpringSimulation(
        SpringDescription(mass: 1, stiffness: 200, damping: 20),
        _position.dy,
        target.dy,
        dy,
      );
      final duration = Duration(milliseconds: 1200);
      ctrl.addListener(() {
        final t = ctrl.value * duration.inMilliseconds / 1000.0;
        if (mounted) {
          setState(() {
            _position = Offset(simX.x(t), simY.x(t));
          });
        }
      });
      ctrl.animateTo(1.0, duration: duration).whenComplete(() {
        ctrl.dispose();
        if (widget.onDismissed != null) widget.onDismissed!();
      });
    } else {
      _springBack();
    }
  }

  void _springBack() {
    final spring = SpringDescription(mass: 1, stiffness: 500, damping: 50);

    final xCtrl = AnimationController.unbounded(vsync: this);
    xCtrl.value = _position.dx;
    final simX = SpringSimulation(spring, _position.dx, 0.0, 0.0);
    xCtrl.animateWith(simX).whenComplete(() => xCtrl.dispose());

    _ctrl.value = _position.dy;
    final simY = SpringSimulation(spring, _position.dy, openY, 0.0);
    _ctrl.animateWith(simY);

    xCtrl.addListener(() {
      if (mounted) {
        setState(() {
          _position = Offset(xCtrl.value, _position.dy);
        });
      }
    });
    _ctrl.addListener(() {
      if (mounted) {
        setState(() {
          _position = Offset(_position.dx, _ctrl.value);
        });
      }
    });
  }

  void _updatePosition(Offset delta) {
    final size = MediaQuery.of(context).size;
    setState(() {
      _position += Offset(delta.dx / size.width, delta.dy / size.height);
    });
  }

  void _handleDragUpdate(DragUpdateDetails d) {
    _updatePosition(d.delta);
  }

  void _handleDragEnd(DragEndDetails d) {
    final size = MediaQuery.of(context).size;
    final velocity = Offset(d.velocity.pixelsPerSecond.dx / size.width, d.velocity.pixelsPerSecond.dy / size.height);
    _hideSheet(velocity: velocity);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _blurCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final size = MediaQuery.of(ctx).size;
    final offsetY = size.height * _position.dy;
    final offsetX = size.width * _position.dx;

    // Calculate normalized deltas from rest
    final horizontalDelta = _position.dx.abs();
    final verticalDelta = (_position.dy - openY).abs();

    // Use the largest delta for both border/blur and scale
    final dragDistance = (horizontalDelta > verticalDelta ? horizontalDelta : verticalDelta) / 0.25;
    final clampedDrag = dragDistance.clamp(0.0, 1.0);

    final borderRadius = BorderRadius.circular(50 * clampedDrag);
    final blurValue = _blurAnim * (1.0 - clampedDrag);

    // --- 50% scale spread: 0.75 at bottom, 1.25 at top, 1.0 at openY ---
    final minScale = 0.75;
    final maxScale = 1.25;

    // Normalized vertical: -1 at top, 0 at openY, 1 at bottom
    final tVert = ((_position.dy - openY) / (1.0 - openY)).clamp(-1.0, 1.0);

    double scale;
    if (tVert < 0) {
      // Dragged up (top): grow
      scale = 1.0 + (maxScale - 1.0) * -tVert;
    } else {
      // Dragged down (bottom): shrink
      scale = 1.0 - (1.0 - minScale) * tVert;
    }

    // Calculate opacity: 1.0 at scale 1.0 or above, 0.75 at scale 0.75
    final minOpacity = 0.75;
    final opacity = minOpacity + ((scale - minScale) / (1.0 - minScale)) * (1.0 - minOpacity);

    Widget sheetContent = ClipRRect(borderRadius: borderRadius, child: widget.builder(ctx));

    sheetContent = Opacity(opacity: opacity.clamp(minOpacity, 1.0), child: sheetContent);

    sheetContent = Transform.scale(scale: scale, alignment: Alignment.topCenter, child: sheetContent);

    return Stack(
      children: [
        Positioned.fill(child: IgnorePointer(ignoring: true, child: Container(color: Colors.transparent))),
        Positioned.fill(
          child: IgnorePointer(
            child: Blur(
              blur: 8 * blurValue,
              colorOpacity: 0.1 * blurValue,
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          top: offsetY,
          left: offsetX,
          width: size.width,
          child: GestureDetector(
            onPanUpdate: _handleDragUpdate,
            onPanEnd: _handleDragEnd,
            child: Material(
              color: Colors.transparent,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              child: SizedBox(width: size.width, height: size.height * widget.openRatio, child: sheetContent),
            ),
          ),
        ),
      ],
    );
  }
}
