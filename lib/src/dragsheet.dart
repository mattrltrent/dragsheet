import 'dart:ui'; // For lerpDouble
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

class DragSheetController {
  OverlayEntry? _entry;

  void show(BuildContext context, WidgetBuilder builder, {bool shrinkWrap = false}) {
    dismiss(); // Remove any previous sheet
    _entry = OverlayEntry(builder: (ctx) => DragSheet(builder: builder, shrinkWrap: shrinkWrap, onDismissed: dismiss));
    Overlay.of(context).insert(_entry!);
  }

  void dismiss() {
    final entry = _entry;
    _entry = null; // <-- Set to null BEFORE removing
    entry?.remove();
  }
}

class DragSheet extends StatefulWidget {
  final WidgetBuilder builder;
  final bool shrinkWrap;
  final VoidCallback? onDismissed;

  const DragSheet({super.key, required this.builder, this.shrinkWrap = false, this.onDismissed});

  @override
  State<DragSheet> createState() => _DragSheetState();
}

class _DragSheetState extends State<DragSheet> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _scaleCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _bgOpacityCtrl;
  late Animation<Offset> _entranceAnim;
  late Animation<double> _bgOpacityAnim;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _bgOpacity = 1.0;
  bool _isDismissing = false;
  bool _didEntrance = false;
  double _clipRadius = 0.0;
  Ticker? _springTicker;

  double _minScale = 1.0;
  double _minRadius = 0.0;
  late double _scaleAtDismiss;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleCtrl.addListener(() {
      if (_isDismissing) {
        setState(() {
          // Animate from the locked scale to 0
          _scale = lerpDouble(_scaleAtDismiss, 0.0, _scaleCtrl.value)!;
          // Animate border radius from locked to 50 (fully rounded) as it shrinks
          _clipRadius = lerpDouble(_minRadius, 80.0, _scaleCtrl.value)!;
        });
      }
    });
    _scaleCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // DO NOT reset _scale or _clipRadius here!
        widget.onDismissed?.call();
      }
    });

    _bgOpacityCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bgOpacityAnim = CurvedAnimation(parent: _bgOpacityCtrl, curve: Curves.easeOut);
    _bgOpacityAnim.addListener(() {
      setState(() {
        _bgOpacity = _bgOpacityAnim.value;
      });
    });

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _entranceAnim = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.ease));

    _entranceCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _didEntrance = true;
        });
      }
    });

    _entranceCtrl.forward();
    _bgOpacityCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scaleCtrl.dispose();
    _entranceCtrl.dispose();
    _bgOpacityCtrl.dispose();
    _springTicker?.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    const effectDistance = 120.0; // <-- Increase this for a more gradual effect
    setState(() {
      _offset += d.delta;
      final dist = _offset.distance.clamp(0, effectDistance);
      final scale = 1.0 - 0.25 * (dist / effectDistance);
      final radius = 50 * (dist / effectDistance);

      // Only allow shrinking
      if (scale < _minScale) _minScale = scale;
      if (radius > _minRadius) _minRadius = radius;

      _scale = _minScale;
      _clipRadius = _minRadius;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond;
    final threshold = 700.0;
    final edgeThreshold = 80.0;
    final size = MediaQuery.of(context).size;

    if (velocity.distance > threshold) {
      _animateWithFriction(velocity);
      return;
    }

    Offset? dismissDir;
    if (_offset.dx.abs() > size.width / 2 - edgeThreshold) {
      dismissDir = Offset(_offset.dx.isNegative ? -1 : 1, 0);
    } else if (_offset.dy.abs() > size.height / 2 - edgeThreshold) {
      dismissDir = Offset(0, _offset.dy.isNegative ? -1 : 1);
    }

    if (dismissDir != null) {
      final target = Offset(dismissDir.dx * size.width * 1.2, dismissDir.dy * size.height * 1.2);
      _animateTo(target, dismiss: true);
    } else {
      _animateTo(Offset.zero);
    }
  }

  void _animateWithFriction(Offset velocity) {
    _springTicker?.dispose();
    _springTicker = null;

    final begin = _offset;
    final beginRadius = _clipRadius;
    final beginScale = _scale;

    // Boost and accelerate velocity
    const minVelocity = 1200.0;
    const velocityMultiplier = 2.0;
    Offset boostedVelocity = velocity * velocityMultiplier;
    if (velocity.distance < minVelocity) {
      final direction = velocity.distance == 0 ? Offset(0, 1) : velocity / velocity.distance;
      boostedVelocity = direction * minVelocity * velocityMultiplier;
    }

    final simX = FrictionSimulation(0.135, begin.dx, boostedVelocity.dx);
    final simY = FrictionSimulation(0.135, begin.dy, boostedVelocity.dy);

    bool fadeStarted = false;

    _springTicker = createTicker((elapsed) {
      final t = elapsed.inMilliseconds / 1000.0;
      final x = simX.x(t);
      final y = simY.x(t);

      setState(() {
        _offset = Offset(x, y);
        _clipRadius = beginRadius;
        _scale = beginScale;
      });

      final size = MediaQuery.of(context).size;
      if (!fadeStarted && (x.abs() > size.width * 0.7 || y.abs() > size.height * 0.7)) {
        fadeStarted = true;
        _bgOpacityCtrl.duration = const Duration(milliseconds: 400); // Make fade-out always smooth
        _bgOpacityCtrl.reverse(from: _bgOpacityCtrl.value);
        _bgOpacityCtrl.addStatusListener((status) {
          if (status == AnimationStatus.dismissed && !_isDismissing) {
            _isDismissing = true;
            widget.onDismissed?.call();
          }
        });
      }
    });
    _springTicker?.start();
  }

  void _animateTo(Offset target, {bool dismiss = false}) {
    _springTicker?.dispose();
    _springTicker = null;

    final begin = _offset;
    final end = target;

    // If dismissing, keep scale and radius fixed during the spring out
    final beginRadius = _clipRadius;
    final endRadius = dismiss ? _clipRadius : (target == Offset.zero ? 0.0 : 50.0);
    final beginScale = _scale;
    final endScale = dismiss ? _scale : (target == Offset.zero ? 1.0 : 0.75);

    final sim = SpringSimulation(SpringDescription(mass: 1, stiffness: 300, damping: 18), 0.0, 1.0, 0.0);

    _springTicker = createTicker((elapsed) {
      final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      final t = sim.x(seconds).clamp(0.0, 1.0);

      setState(() {
        _offset = Offset.lerp(begin, end, t)!;
        _clipRadius = lerpDouble(beginRadius, endRadius, t)!;
        _scale = lerpDouble(beginScale, endScale, t)!;
      });

      if (t >= 1.0) {
        _springTicker?.stop();
        _springTicker?.dispose();
        _springTicker = null;
        setState(() {
          _offset = end;
          _clipRadius = endRadius;
          _scale = endScale;
          if (end == Offset.zero) {
            _minScale = 1.0;
            _minRadius = 0.0;
          }
        });
        if (dismiss && !_isDismissing) {
          _isDismissing = true;
          _scaleAtDismiss = _scale;
          _minRadius = _clipRadius;
          _animateScaleDown();
        }
      }
    });
    _springTicker?.start();

    if (dismiss && !_isDismissing) {
      _isDismissing = true;
      _scaleAtDismiss = _scale;
      _minRadius = _clipRadius;
      _animateScaleDown();
    }
  }

  void _animateScaleDown({Duration duration = const Duration(milliseconds: 500)}) {
    _bgOpacityCtrl.duration = duration;
    _scaleCtrl.duration = duration;
    _bgOpacityCtrl.reverse(from: _bgOpacityCtrl.value);
    _scaleCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final sheet = ClipRRect(
      borderRadius: BorderRadius.circular(_clipRadius),
      child: Material(
        color: Colors.white,
        borderRadius: widget.shrinkWrap ? BorderRadius.vertical(top: Radius.circular(24)) : null,
        child: widget.builder(context),
      ),
    );

    Widget child = Transform.scale(scale: _scale, child: sheet);

    if (widget.shrinkWrap) {
      child = Align(alignment: Alignment.bottomCenter, child: Transform.translate(offset: _offset, child: child));
    } else {
      child = Transform.translate(offset: _offset, child: SizedBox.expand(child: child));
    }

    if (!_didEntrance) {
      child = SlideTransition(position: _entranceAnim, child: child);
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          IgnorePointer(ignoring: true, child: Container(color: Colors.black54.withOpacity(_bgOpacity * 0.5))),
          if (widget.shrinkWrap)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: GestureDetector(onPanUpdate: _onPanUpdate, onPanEnd: _onPanEnd, child: child),
              ),
            )
          else
            SizedBox.expand(child: GestureDetector(onPanUpdate: _onPanUpdate, onPanEnd: _onPanEnd, child: child)),
        ],
      ),
    );
  }
}

final borderRadius = BorderRadius.circular(24);
