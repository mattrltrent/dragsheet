import 'dart:ui'; // For lerpDouble
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

const Duration kOpacityDuration = Duration(milliseconds: 200); // Opacity animation duration

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
    double minScale = 0.85,
    double maxScale = 1.0,
    double minRadius = 0.0,
    double maxRadius = 30.0,
    double minOpacity = 0.0,
    double maxOpacity = 0.5,
    Duration entranceDuration = const Duration(milliseconds: 200),
    Duration exitDuration = const Duration(milliseconds: 200),
    Duration gestureFadeDuration = const Duration(milliseconds: 200),
    Duration programmaticFadeDuration = const Duration(milliseconds: 200),
    double effectDistance = 220.0,
    BgOpacity? bgOpacity,
    double swipeVelocityMultiplier = 2.5,
    double swipeAccelerationThreshold = 50.0, // super low, triggers acceleration easily
    double swipeAccelerationMultiplier = 12.0, // much higher, speeds up dismiss
    double swipeMinVelocity = 1000.0,
    double swipeMaxVelocity = 10000.0,
    double swipeFriction = 0.09,
    VoidCallback? onShow,
    VoidCallback? onDismiss,
    Duration opacityDuration = const Duration(milliseconds: 200), // <-- Add this
  }) {
    // DO NOT CHANGE LINE ABOVE THIS LINE
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
            opacityDuration: opacityDuration, // <-- Pass it down
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

  final Duration opacityDuration; // <-- Add this

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
    this.opacityDuration = const Duration(milliseconds: 200), // <-- Add this
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

  // Add this field:
  AnimationStatusListener? _gravityDismissOpacityListener;

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

    _bgOpacityCtrl = AnimationController(
      vsync: this,
      duration: widget.opacityDuration,
    ); // <-- Use widget.opacityDuration
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
    _removeGravityDismissOpacityListener(); // Add this
    _springTicker?.dispose();
    super.dispose();
  }

  void _removeGravityDismissOpacityListener() {
    if (_gravityDismissOpacityListener != null) {
      if (_bgOpacityCtrl.isAnimating || _bgOpacityCtrl.status != AnimationStatus.dismissed) {
        // Only remove if the controller is still active and listener might be there.
        // Check _bgOpacityCtrl.owner != null if more safety needed (controller not disposed)
      }
      // Try removing, Flutter's AnimationController is robust to removing non-existent listeners.
      _bgOpacityCtrl.removeStatusListener(_gravityDismissOpacityListener!);
      _gravityDismissOpacityListener = null;
    }
  }

  void _onPanStart(DragStartDetails d) {
    _cancelSpringTicker(); // Stops physics animation (calls _springTicker?.dispose())
    if (_isDismissing) {
      // If a gesture-based dismiss (fling) was in progress:
      _bgOpacityCtrl.stop(); // Stop the background fade
      _removeGravityDismissOpacityListener(); // Remove the specific listener for onDismissed
      _isDismissing = false; // No longer in a dismiss state initiated by fling
      setState(() {
        _ignoreAllPointers = false;
      }); // Allow interaction again
      // The opacity will be left as is; subsequent _onPanUpdate will adjust it.
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _cancelSpringTicker();
    setState(() {
      _offset += d.delta;
      final dist = _offset.distance.clamp(0, widget.effectDistance);

      // Interpolate scale and radius based on drag distance
      _scale = widget.maxScale - (widget.maxScale - widget.minScale) * (dist / widget.effectDistance);
      _clipRadius = widget.minRadius + (widget.maxRadius - widget.minRadius) * (dist / widget.effectDistance);
    });

    // Track velocity and time for acceleration calculation
    _lastVelocity = d.delta / (d.sourceTimeStamp?.inMilliseconds.toDouble() ?? 16) * 1000;
    _lastVelocityTime = DateTime.now();
  }

  void _onPanEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond;
    final velocityMagnitude = velocity.distance;
    final minDismissVelocity = 200.0;

    final angle = velocity.direction * 180 / 3.1415926535897932;
    final normalizedAngle = (angle + 360) % 360;
    final isDownward = normalizedAngle >= 45 && normalizedAngle <= 135;

    if (velocityMagnitude > minDismissVelocity && isDownward) {
      _animateWithGravity(velocity, acceleration: 8000.0); // try 8000-12000 for a fast whoosh
      return;
    }

    _animateTo(Offset.zero);
  }

  void _animateWithFriction(
    Offset velocity, {
    double velocityMultiplier = 3.5,
    double minVelocity = 2500.0, // <-- bump this up!
    double maxVelocity = 10000.0,
    double friction = 0.09,
  }) {
    _springTicker?.dispose();
    _springTicker = null;

    final begin = _offset;
    final beginRadius = _clipRadius;
    final beginScale = _scale;

    double speed = velocity.distance * velocityMultiplier;
    // Always use at least minVelocity, even for slow swipes!
    speed = speed < minVelocity ? minVelocity : speed;
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

    final isBouncy = target == Offset.zero;
    final spring =
        isBouncy
            ? SpringDescription(mass: 1, stiffness: 340, damping: 20)
            : SpringDescription(mass: 1, stiffness: 300, damping: 24);

    final sim = SpringSimulation(spring, 0.0, 1.0, 0.0);

    _springTicker = createTicker((elapsed) {
      final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      final t = sim.x(seconds);

      setState(() {
        _offset = Offset.lerp(begin, end, t)!;
        _clipRadius = lerpDouble(beginRadius, endRadius, t)!;
        _scale = lerpDouble(beginScale, endScale, t)!;
      });

      // Only stop when the simulation is "done" (close to target and velocity is low)
      if (sim.isDone(seconds)) {
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
            // Haptic feedback on bounce back
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

  void _animateScaleDown({Duration? duration}) {
    setState(() {
      _ignoreAllPointers = true;
    });
    final d = duration ?? widget.opacityDuration; // <-- Use widget.opacityDuration as default
    _bgOpacityCtrl.duration = d;
    _scaleCtrl.duration = d;
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

  void _cancelSpringTicker() {
    if (_springTicker != null) {
      _springTicker?.stop();
      _springTicker?.dispose();
      _springTicker = null;
    }
  }

  void _animateWithGravity(Offset velocity, {double acceleration = 8000.0}) {
    _springTicker?.dispose(); // Dispose previous physics ticker
    _springTicker = null;

    // If already dismissing via another path, or if this is a re-fling,
    // ensure old listeners specific to gravity dismiss are cleared.
    _removeGravityDismissOpacityListener();

    _isDismissing = true; // Mark that we are in a dismiss process
    setState(() {
      _ignoreAllPointers = true;
    });

    // START BACKGROUND OPACITY FADE IMMEDIATELY
    _bgOpacityCtrl.duration = widget.gestureFadeDuration;
    _bgOpacityCtrl.reverse(from: _bgOpacityCtrl.value);

    // Setup listener for when this specific fade completes to call onDismissed
    _gravityDismissOpacityListener = (AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        // Only call onDismissed if we are *still* in the dismiss state
        // initiated by this call to _animateWithGravity.
        // This check is important if the dismiss was cancelled by _onPanStart.
        if (_isDismissing) {
          widget.onDismissed?.call();
          // _isDismissing will be effectively reset when the controller removes the sheet.
        }
        _removeGravityDismissOpacityListener(); // Clean up self
      }
    };
    _bgOpacityCtrl.addStatusListener(_gravityDismissOpacityListener!);

    final begin = _offset;
    final beginRadius = _clipRadius; // Lock radius during fling
    final beginScale = _scale; // Lock scale during fling

    final direction = velocity.distance == 0 ? Offset(0, 1) : velocity / velocity.distance;
    const double minVel = 100.0;

    // --- X-axis Simulation ---
    double effectiveAccelX = acceleration * direction.dx.sign;
    if (direction.dx.abs() < 1e-3) effectiveAccelX = 0.0;

    double currentBeginX = begin.dx;
    double physicalTargetX;
    if (effectiveAccelX > 0)
      physicalTargetX = currentBeginX + 2000.0;
    else if (effectiveAccelX < 0)
      physicalTargetX = currentBeginX - 2000.0;
    else
      physicalTargetX = currentBeginX;

    double currentVX = velocity.dx.abs() < minVel ? minVel * direction.dx.sign : velocity.dx;

    GravitySimulation simX;
    double xPosMultiplier = 1.0;

    if (effectiveAccelX == 0.0) {
      simX = GravitySimulation(0.0, currentBeginX, physicalTargetX, currentVX);
    } else {
      double simConsAccel, simConsBegin, simConsEnd, simConsVel;
      if (physicalTargetX >= currentBeginX) {
        simConsAccel = effectiveAccelX;
        simConsBegin = currentBeginX;
        simConsEnd = physicalTargetX;
        simConsVel = currentVX;
        xPosMultiplier = 1.0;
      } else {
        simConsAccel = -effectiveAccelX;
        simConsBegin = -currentBeginX;
        simConsEnd = -physicalTargetX;
        simConsVel = -currentVX;
        xPosMultiplier = -1.0;
      }
      simX = GravitySimulation(simConsAccel, simConsBegin, simConsEnd, simConsVel);
    }

    // --- Y-axis Simulation (similar logic) ---
    double effectiveAccelY = acceleration * direction.dy.sign;
    if (direction.dy.abs() < 1e-3) effectiveAccelY = 0.0;

    double currentBeginY = begin.dy;
    double physicalTargetY;
    if (effectiveAccelY > 0)
      physicalTargetY = currentBeginY + 2000.0;
    else if (effectiveAccelY < 0)
      physicalTargetY = currentBeginY - 2000.0;
    else
      physicalTargetY = currentBeginY;

    double currentVY = velocity.dy.abs() < minVel ? minVel * direction.dy.sign : velocity.dy;

    GravitySimulation simY;
    double yPosMultiplier = 1.0;

    if (effectiveAccelY == 0.0) {
      simY = GravitySimulation(0.0, currentBeginY, physicalTargetY, currentVY);
    } else {
      double simConsAccel, simConsBegin, simConsEnd, simConsVel;
      if (physicalTargetY >= currentBeginY) {
        simConsAccel = effectiveAccelY;
        simConsBegin = currentBeginY;
        simConsEnd = physicalTargetY;
        simConsVel = currentVY;
        yPosMultiplier = 1.0;
      } else {
        simConsAccel = -effectiveAccelY;
        simConsBegin = -currentBeginY;
        simConsEnd = -physicalTargetY;
        simConsVel = -currentVY;
        yPosMultiplier = -1.0;
      }
      simY = GravitySimulation(simConsAccel, simConsBegin, simConsEnd, simConsVel);
    }

    _springTicker = createTicker((elapsed) {
      final t = elapsed.inMilliseconds / 1000.0;
      // Check if simulations are valid before calling x(t)
      // This is a safeguard, though the logic above should prevent invalid states.
      if (simX == null || simY == null) return;

      final x = xPosMultiplier * simX.x(t);
      final y = yPosMultiplier * simY.x(t);

      setState(() {
        _offset = Offset(x, y);
        _clipRadius = beginRadius;
        _scale = beginScale;
      });

      // The onDismissed callback is now handled by the _gravityDismissOpacityListener
      // No need for fadeStarted or explicit onDismissed calls from the ticker here.
    });
    _springTicker?.start();
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
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Stack(
          children: [
            if (_bgOpacity > 0 && bgOpacity.opacity > 0 && bgOpacity.color.opacity > 0)
              Positioned.fill(child: ColoredBox(color: bgOpacity.color.withOpacity(_bgOpacity * bgOpacity.opacity))),
            widget.shrinkWrap
                ? Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onTapDown: (_) => _cancelSpringTicker(),
                      child: child,
                    ),
                  ),
                )
                : SizedBox.expand(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTapDown: (_) => _cancelSpringTicker(),
                    child: child,
                  ),
                ),
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
