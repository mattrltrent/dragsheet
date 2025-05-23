import 'dart:ui'; // For lerpDouble
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

class DragSheetController extends ChangeNotifier {
  OverlayEntry? _entry;
  GlobalKey<_DragSheetState>? _sheetKey;

  /// Optional callbacks for show/dismiss events
  VoidCallback? onShow;
  VoidCallback? onDismiss;

  bool _isOpen = false;
  bool get isOpen => _isOpen;

  void show(
    BuildContext context,
    WidgetBuilder builder, {
    bool shrinkWrap = false,
    double minScale = 0.75,
    double maxScale = 1.0,
    double minRadius = 0.0,
    double maxRadius = 50.0,
    double minOpacity = 0.0,
    double maxOpacity = 0.5,
    Duration entranceDuration = const Duration(milliseconds: 200),
    Duration exitDuration = const Duration(milliseconds: 200),
    Duration gestureFadeDuration = const Duration(milliseconds: 300),
    Duration programmaticFadeDuration = const Duration(milliseconds: 1000),
    double effectDistance = 120.0,
    BgOpacity? bgOpacity,
    double swipeVelocityMultiplier = 3.5,
    double swipeAccelerationThreshold = 3000,
    double swipeAccelerationMultiplier = 6.0,
    double swipeMinVelocity = 1800.0,
    double swipeMaxVelocity = 5000.0,
    double swipeFriction = 0.09,
    VoidCallback? onShow,
    VoidCallback? onDismiss,
  }) {
    // Ensure previous entry is removed before creating a new one
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
      _sheetKey = null;
      _isOpen = false;
    }

    _sheetKey = GlobalKey<_DragSheetState>();
    this.onShow = onShow;
    this.onDismiss = onDismiss;
    _isOpen = true;
    notifyListeners();
    _entry = OverlayEntry(
      builder:
          (ctx) => DragSheet(
            key: _sheetKey,
            builder: builder,
            shrinkWrap: shrinkWrap,
            onDismissed: () {
              _removeEntry();
              if (this.onDismiss != null) this.onDismiss!();
            },
            onShow: this.onShow,
            minScale: minScale,
            maxScale: maxScale,
            minRadius: minRadius,
            maxRadius: maxRadius,
            minOpacity: minOpacity,
            maxOpacity: maxOpacity,
            entranceDuration: entranceDuration,
            exitDuration: exitDuration,
            gestureFadeDuration: gestureFadeDuration,
            programmaticFadeDuration: programmaticFadeDuration,
            effectDistance: effectDistance,
            bgOpacity: bgOpacity,
            swipeVelocityMultiplier: swipeVelocityMultiplier,
            swipeAccelerationThreshold: swipeAccelerationThreshold,
            swipeAccelerationMultiplier: swipeAccelerationMultiplier,
            swipeMinVelocity: swipeMinVelocity,
            swipeMaxVelocity: swipeMaxVelocity,
            swipeFriction: swipeFriction,
          ),
    );
    Overlay.of(context).insert(_entry!);
    if (this.onShow != null) this.onShow!();
  }

  void dismiss() {
    if (_isOpen) {
      _sheetKey?.currentState?.animateDismiss();
    }
  }

  void _removeEntry() {
    final entry = _entry;
    _entry = null;
    entry?.remove();
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }
}

class DragSheet extends StatefulWidget {
  final WidgetBuilder builder;
  final bool shrinkWrap;
  final VoidCallback? onDismissed;
  final VoidCallback? onShow;

  // Configurable constants
  final double minScale;
  final double maxScale;
  final double minRadius;
  final double maxRadius;
  final double minOpacity;
  final double maxOpacity;
  final Duration entranceDuration;
  final Duration exitDuration;
  final Duration gestureFadeDuration;
  final Duration programmaticFadeDuration;
  final double effectDistance;
  final BgOpacity? bgOpacity;

  // Swipe physics parameters
  final double swipeVelocityMultiplier;
  final double swipeAccelerationThreshold;
  final double swipeAccelerationMultiplier;
  final double swipeMinVelocity;
  final double swipeMaxVelocity;
  final double swipeFriction;

  const DragSheet({
    Key? key,
    required this.builder,
    required this.shrinkWrap,
    this.onDismissed,
    this.onShow,
    this.minScale = 0.75,
    this.maxScale = 1.0,
    this.minRadius = 0.0,
    this.maxRadius = 50.0,
    this.minOpacity = 0.0,
    this.maxOpacity = 0.5,
    this.entranceDuration = const Duration(milliseconds: 200),
    this.exitDuration = const Duration(milliseconds: 200),
    this.gestureFadeDuration = const Duration(milliseconds: 300),
    this.programmaticFadeDuration = const Duration(milliseconds: 1000),
    this.effectDistance = 120.0,
    this.bgOpacity,
    this.swipeVelocityMultiplier = 3.5,
    this.swipeAccelerationThreshold = 3000,
    this.swipeAccelerationMultiplier = 6.0,
    this.swipeMinVelocity = 1800.0,
    this.swipeMaxVelocity = 5000.0,
    this.swipeFriction = 0.09,
  }) : super(key: key);

  @override
  State<DragSheet> createState() => _DragSheetState();
}

class _DragSheetState extends State<DragSheet> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _scaleCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _bgOpacityCtrl;
  late AnimationController _exitCtrl;
  late Animation<Offset> _entranceAnim;
  late Animation<Offset> _exitAnim;
  late Animation<double> _bgOpacityAnim;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _bgOpacity = 1.0;
  bool _isDismissing = false;
  bool _didEntrance = false;
  bool _isExiting = false;
  double _clipRadius = 0.0;
  Ticker? _springTicker;

  double _minScale = 1.0;
  double _minRadius = 0.0;
  late double _scaleAtDismiss;

  bool _ignoreAllPointers = false;

  // Add these fields to _DragSheetState:
  Offset? _lastVelocity;
  DateTime? _lastVelocityTime;

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

    _entranceCtrl = AnimationController(vsync: this, duration: widget.entranceDuration);
    _entranceAnim = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.ease));

    _exitCtrl = AnimationController(vsync: this, duration: widget.exitDuration);
    _exitAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, 1),
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.ease));

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
    _exitCtrl.dispose();
    _springTicker?.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _offset += d.delta;
      final dist = _offset.distance.clamp(0, widget.effectDistance);
      final scale = widget.maxScale - (widget.maxScale - widget.minScale) * (dist / widget.effectDistance);
      final radius = widget.minRadius + (widget.maxRadius - widget.minRadius) * (dist / widget.effectDistance);

      if (scale < _minScale) _minScale = scale;
      if (radius > _minRadius) _minRadius = radius;

      _scale = _minScale;
      _clipRadius = _minRadius;
    });

    // Track velocity and time for acceleration calculation
    _lastVelocity = d.delta / (d.sourceTimeStamp?.inMilliseconds.toDouble() ?? 16) * 1000;
    _lastVelocityTime = DateTime.now();
  }

  void _onPanEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond;
    final threshold = 700.0;
    final edgeThreshold = 80.0;
    final size = MediaQuery.of(context).size;

    // Calculate acceleration if possible
    double acceleration = 0.0;
    if (_lastVelocity != null && _lastVelocityTime != null) {
      final timeDiff = DateTime.now().difference(_lastVelocityTime!).inMilliseconds / 1000.0;
      if (timeDiff > 0) {
        final velocityDiff = (velocity - _lastVelocity!).distance;
        acceleration = velocityDiff / timeDiff;
      }
    }

    // Use widget's swipe physics parameters
    double velocityMultiplier = widget.swipeVelocityMultiplier;
    if (acceleration > widget.swipeAccelerationThreshold) {
      velocityMultiplier = widget.swipeAccelerationMultiplier;
    }

    if (velocity.distance > threshold) {
      _animateWithFriction(
        velocity,
        velocityMultiplier: velocityMultiplier,
        minVelocity: widget.swipeMinVelocity,
        maxVelocity: widget.swipeMaxVelocity,
        friction: widget.swipeFriction,
      );
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

  void _animateWithFriction(
    Offset velocity, {
    double velocityMultiplier = 3.5,
    double minVelocity = 1800.0,
    double maxVelocity = 5000.0,
    double friction = 0.09,
  }) {
    _springTicker?.dispose();
    _springTicker = null;

    final begin = _offset;
    final beginRadius = _clipRadius;
    final beginScale = _scale;

    double speed = velocity.distance * velocityMultiplier;
    speed = speed.clamp(minVelocity, maxVelocity);
    final direction = velocity.distance == 0 ? Offset(0, 1) : velocity / velocity.distance;
    final boostedVelocity = direction * speed;

    final simX = FrictionSimulation(friction, begin.dx, boostedVelocity.dx);
    final simY = FrictionSimulation(friction, begin.dy, boostedVelocity.dy);

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
        setState(() {
          _ignoreAllPointers = true;
        });
        _bgOpacityCtrl.duration = widget.gestureFadeDuration;
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

  void _animateScaleDown({Duration duration = const Duration(milliseconds: 300)}) {
    // <-- fast fade for swipe
    setState(() {
      _ignoreAllPointers = true;
    });
    _bgOpacityCtrl.duration = duration;
    _scaleCtrl.duration = duration;
    _bgOpacityCtrl.reverse(from: _bgOpacityCtrl.value);
    _scaleCtrl.forward(from: 0);
  }

  void animateDismiss() async {
    if (!_isDismissing && !_isExiting) {
      _isDismissing = true;
      _isExiting = true;
      setState(() {
        _ignoreAllPointers = true; // Block interaction during animation
      });
      _bgOpacityCtrl.duration = widget.programmaticFadeDuration;
      if (_bgOpacityCtrl.value == 0) {
        _bgOpacityCtrl.value = 1.0;
      }
      final fade = _bgOpacityCtrl.reverse(from: _bgOpacityCtrl.value);
      final slide = _exitCtrl.forward();
      await Future.wait([fade, slide]);
      setState(() {
        _ignoreAllPointers = false; // Allow interaction again
      });
      widget.onDismissed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgOpacity = widget.bgOpacity ?? BgOpacity.kDefault;

    final sheet = ClipRRect(
      borderRadius: BorderRadius.circular(_clipRadius),
      child: Material(
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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

    // Animate in or out
    if (!_didEntrance) {
      child = SlideTransition(position: _entranceAnim, child: child);
    } else if (_isExiting) {
      child = SlideTransition(position: _exitAnim, child: child);
    }

    return IgnorePointer(
      ignoring: _ignoreAllPointers,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            if (_bgOpacity > 0)
              Positioned.fill(child: ColoredBox(color: bgOpacity.color.withOpacity(_bgOpacity * bgOpacity.opacity))),
            widget.shrinkWrap
                ? Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: GestureDetector(onPanUpdate: _onPanUpdate, onPanEnd: _onPanEnd, child: child),
                  ),
                )
                : SizedBox.expand(child: GestureDetector(onPanUpdate: _onPanUpdate, onPanEnd: _onPanEnd, child: child)),
          ],
        ),
      ),
    );
  }
}

final borderRadius = BorderRadius.circular(24);

class BgOpacity {
  final Color color;
  final double opacity; // 0.0 to 1.0
  const BgOpacity({required this.color, this.opacity = 0.5});

  static const BgOpacity kDefault = BgOpacity(color: Colors.black, opacity: 0.5);
}
