import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Manages the presentation and dismissal of a [DragSheet].
///
/// This controller allows showing a sheet as an overlay entry and dismissing it.
/// It also provides a way to listen to the sheet's visibility state.
class DragSheetController extends ChangeNotifier {
  OverlayEntry? _entry;
  GlobalKey<_DragSheetState>? _sheetKey;

  /// Optional callback triggered when the sheet becomes fully visible.
  VoidCallback? onShow;

  /// Optional callback triggered when the sheet is fully dismissed.
  VoidCallback? onDismiss;

  bool _isOpen = false;

  /// Returns `true` if the sheet is currently presented, `false` otherwise.
  bool get isOpen => _isOpen;

  /// Displays the drag sheet.
  ///
  /// [context] is the build context from which to present the sheet.
  /// [builder] is a widget builder function for the sheet's content.
  ///
  /// Optional parameters allow customization of the sheet's appearance and behavior:
  /// [shrinkWrap] determines if the sheet should only take up necessary vertical space.
  /// [minScale], [maxScale] control the scaling effect during drag.
  /// [minRadius], [maxRadius] control the corner radius effect during drag.
  /// [minOpacity], [maxOpacity] control the background dimming opacity.
  /// [entranceDuration], [exitDuration] define the animation durations for programmatic show/hide.
  /// [gestureFadeDuration] is the duration for the background to fade when dismissing via gesture.
  /// [programmaticFadeDuration] is the duration for the background to fade when dismissing programmatically.
  /// [effectDistance] is the drag distance over which scaling and radius effects are applied.
  /// [bgOpacity] customizes the background color and opacity.
  /// [swipeVelocityMultiplier], [swipeAccelerationThreshold], [swipeAccelerationMultiplier],
  /// [swipeMinVelocity], [swipeMaxVelocity], [swipeFriction] control swipe gesture physics.
  /// [onShow], [onDismiss] are callbacks for sheet visibility events.
  /// [opacityDuration] is the duration for opacity animations, particularly for background and scale-down.
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
    double swipeAccelerationThreshold = 50.0,
    double swipeAccelerationMultiplier = 12.0,
    double swipeMinVelocity = 1000.0,
    double swipeMaxVelocity = 10000.0,
    double swipeFriction = 0.09,
    VoidCallback? onShow,
    VoidCallback? onDismiss,
    Duration opacityDuration = const Duration(milliseconds: 200),
  }) {
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
            opacityDuration: opacityDuration,
          ),
    );
    Overlay.of(context).insert(_entry!);
    if (this.onShow != null) this.onShow!();
  }

  /// Programmatically dismisses the sheet if it is currently open.
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

/// A widget that can be dragged and dismissed, typically used for modal sheets.
///
/// It supports gestures for dragging and flinging to dismiss, along with
/// configurable animations and physics.
class DragSheet extends StatefulWidget {
  /// Builds the content of the sheet.
  final WidgetBuilder builder;

  /// If `true`, the sheet will take up only the necessary vertical space for its content.
  /// If `false`, it will expand to fill available vertical space.
  final bool shrinkWrap;

  /// Called when the sheet has been fully dismissed.
  final VoidCallback? onDismissed;

  /// Called when the sheet has been fully shown.
  final VoidCallback? onShow;

  /// The minimum scale factor applied to the sheet during drag.
  final double minScale;

  /// The maximum scale factor (typically 1.0 for full size).
  final double maxScale;

  /// The minimum corner radius applied during drag (typically 0.0 for squared corners).
  final double minRadius;

  /// The maximum corner radius applied when the sheet is scaled down.
  final double maxRadius;

  /// The minimum opacity of the background scrim.
  final double minOpacity;

  /// The maximum opacity of the background scrim.
  final double maxOpacity;

  /// Duration of the entrance animation when the sheet is shown.
  final Duration entranceDuration;

  /// Duration of the exit animation when the sheet is dismissed programmatically.
  final Duration exitDuration;

  /// Duration of the background fade when dismissing via a gesture.
  final Duration gestureFadeDuration;

  /// Duration of the background fade when dismissing programmatically.
  final Duration programmaticFadeDuration;

  /// The distance over which drag effects (scale, radius) are interpolated.
  final double effectDistance;

  /// Configuration for the background scrim's color and opacity.
  final BgOpacity? bgOpacity;

  /// Multiplier for swipe velocity to determine fling strength.
  final double swipeVelocityMultiplier;

  /// Threshold for detecting acceleration in swipe gestures.
  final double swipeAccelerationThreshold;

  /// Multiplier for swipe acceleration to enhance fling speed.
  final double swipeAccelerationMultiplier;

  /// Minimum velocity for a swipe to be considered a fling.
  final double swipeMinVelocity;

  /// Maximum velocity for a swipe fling.
  final double swipeMaxVelocity;

  /// Friction applied to fling animations.
  final double swipeFriction;

  /// Duration for opacity-related animations, such as background fade and scale-down effects.
  final Duration opacityDuration;

  /// Creates a [DragSheet].
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
    this.opacityDuration = const Duration(milliseconds: 200),
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

  AnimationStatusListener? _gravityDismissOpacityListener;

  double _minScale = 1.0;
  double _minRadius = 0.0;
  late double _scaleAtDismiss;

  bool _ignoreAllPointers = false;

  Offset? _lastVelocity;
  DateTime? _lastVelocityTime;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleCtrl.addListener(() {
      if (_isDismissing) {
        setState(() {
          _scale = lerpDouble(_scaleAtDismiss, 0.0, _scaleCtrl.value)!;
          _clipRadius = lerpDouble(_minRadius, 80.0, _scaleCtrl.value)!;
        });
      }
    });
    _scaleCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed?.call();
      }
    });

    _bgOpacityCtrl = AnimationController(
      vsync: this,
      duration: widget.opacityDuration,
    );
    _bgOpacityAnim = CurvedAnimation(
      parent: _bgOpacityCtrl,
      curve: Curves.easeOut,
    );
    _bgOpacityAnim.addListener(() {
      setState(() {
        _bgOpacity = _bgOpacityAnim.value;
      });
    });

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: widget.entranceDuration,
    );
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
    _removeGravityDismissOpacityListener();
    _springTicker?.dispose();
    super.dispose();
  }

  void _removeGravityDismissOpacityListener() {
    if (_gravityDismissOpacityListener != null) {
      if (_bgOpacityCtrl.isAnimating ||
          _bgOpacityCtrl.status != AnimationStatus.dismissed) {}
      _bgOpacityCtrl.removeStatusListener(_gravityDismissOpacityListener!);
      _gravityDismissOpacityListener = null;
    }
  }

  void _onPanStart(DragStartDetails d) {
    _cancelSpringTicker();
    if (_isDismissing) {
      _bgOpacityCtrl.stop();
      _removeGravityDismissOpacityListener();
      _isDismissing = false;
      setState(() {
        _ignoreAllPointers = false;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _cancelSpringTicker();
    setState(() {
      _offset += d.delta;
      final dist = _offset.distance.clamp(0, widget.effectDistance);

      _scale =
          widget.maxScale -
          (widget.maxScale - widget.minScale) * (dist / widget.effectDistance);
      _clipRadius =
          widget.minRadius +
          (widget.maxRadius - widget.minRadius) *
              (dist / widget.effectDistance);
    });

    _lastVelocity =
        d.delta / (d.sourceTimeStamp?.inMilliseconds.toDouble() ?? 16) * 1000;
    _lastVelocityTime = DateTime.now();
  }

  void _onPanEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond;
    final velocityMagnitude = velocity.distance;
    final minDismissVelocity = 200.0;

    final angle = velocity.direction * 180 / 3.1415926535897932;
    final normalizedAngle = (angle + 360) % 360;
    final isDismissDirection = normalizedAngle >= 0 && normalizedAngle <= 180;

    if (velocityMagnitude > minDismissVelocity && isDismissDirection) {
      _animateWithGravity(velocity, acceleration: 8000.0);
      return;
    }

    _animateTo(Offset.zero);
  }

  void _animateWithFriction(
    Offset velocity, {
    double velocityMultiplier = 3.5,
    double minVelocity = 2500.0,
    double maxVelocity = 10000.0,
    double friction = 0.09,
  }) {
    _springTicker?.dispose();
    _springTicker = null;

    final begin = _offset;
    final beginRadius = _clipRadius;
    final beginScale = _scale;

    double speed = velocity.distance * velocityMultiplier;
    speed = speed < minVelocity ? minVelocity : speed;
    speed = speed.clamp(minVelocity, maxVelocity);
    final direction =
        velocity.distance == 0 ? Offset(0, 1) : velocity / velocity.distance;
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
      if (!fadeStarted &&
          (x.abs() > size.width * 0.7 || y.abs() > size.height * 0.7)) {
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

    final beginRadius = _clipRadius;
    final endRadius =
        dismiss ? _clipRadius : (target == Offset.zero ? 0.0 : 50.0);
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
    final d = duration ?? widget.opacityDuration;
    _bgOpacityCtrl.duration = d;
    _scaleCtrl.duration = d;
    _bgOpacityCtrl.reverse(from: _bgOpacityCtrl.value);
    _scaleCtrl.forward(from: 0);
  }

  /// Initiates the programmatic dismissal animation of the sheet.
  ///
  /// This involves fading out the background and sliding the sheet off-screen.
  /// Pointers are ignored during this animation.
  void animateDismiss() async {
    if (!_isDismissing && !_isExiting) {
      _isDismissing = true;
      _isExiting = true;
      setState(() {
        _ignoreAllPointers = true;
      });
      _bgOpacityCtrl.duration = widget.programmaticFadeDuration;
      if (_bgOpacityCtrl.value == 0) {
        _bgOpacityCtrl.value = 1.0;
      }
      final fade = _bgOpacityCtrl.reverse(from: _bgOpacityCtrl.value);
      final slide = _exitCtrl.forward();
      await Future.wait([fade, slide]);
      setState(() {
        _ignoreAllPointers = false;
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
    _springTicker?.dispose();
    _springTicker = null;
    _removeGravityDismissOpacityListener();
    _isDismissing = true;
    setState(() {
      _ignoreAllPointers = true;
    });

    _bgOpacityCtrl.duration = widget.gestureFadeDuration;
    _bgOpacityCtrl.reverse(from: _bgOpacityCtrl.value);
    _gravityDismissOpacityListener = (AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        if (_isDismissing) {
          _cancelSpringTicker();
          widget.onDismissed?.call();
        }
        _removeGravityDismissOpacityListener();
      }
    };
    _bgOpacityCtrl.addStatusListener(_gravityDismissOpacityListener!);

    final beginOffset = _offset;
    final beginRadius = _clipRadius;
    final beginScale = _scale;

    const double flingBoundaryDistance = 2000.0;
    final double accelMagnitude = acceleration.abs();

    final double xSign = velocity.dx < 0 ? -1.0 : 1.0;
    final double ySign = velocity.dy < 0 ? -1.0 : 1.0;

    final double simStartX = beginOffset.dx * xSign;
    final double simVelX = velocity.dx * xSign;
    final double simAccelX = velocity.dx.abs() < 1e-3 ? 0.0 : accelMagnitude;

    final GravitySimulation simX = GravitySimulation(
      simAccelX,
      simStartX,
      flingBoundaryDistance,
      simVelX,
    );

    final double simStartY = beginOffset.dy * ySign;
    final double simVelY = velocity.dy * ySign;
    final double simAccelY = velocity.dy.abs() < 1e-3 ? 0.0 : accelMagnitude;

    final GravitySimulation simY = GravitySimulation(
      simAccelY,
      simStartY,
      flingBoundaryDistance,
      simVelY,
    );

    _springTicker = createTicker((elapsed) {
      final t = elapsed.inMilliseconds / 1000.0;

      final double currentSimX = simX.x(t);
      final double currentSimY = simY.x(t);

      final newOffsetX = currentSimX * xSign;
      final newOffsetY = currentSimY * ySign;

      final screenSize = MediaQuery.of(context).size;
      if ((newOffsetX.abs() > screenSize.width * 1.5 && simAccelX != 0) ||
          (newOffsetY.abs() > screenSize.height * 1.5 && simAccelY != 0)) {
        if (!_bgOpacityCtrl.isAnimating &&
            _bgOpacityCtrl.status == AnimationStatus.dismissed) {
          _cancelSpringTicker();
          return;
        }
      }

      setState(() {
        _offset = Offset(newOffsetX, newOffsetY);
        _clipRadius = beginRadius;
        _scale = beginScale;
      });
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
        borderRadius:
            widget.shrinkWrap
                ? BorderRadius.vertical(top: Radius.circular(24))
                : null,
        child: widget.builder(context),
      ),
    );

    Widget child = Transform.scale(scale: _scale, child: sheet);

    if (widget.shrinkWrap) {
      child = Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(offset: _offset, child: child),
      );
    } else {
      child = Transform.translate(
        offset: _offset,
        child: SizedBox.expand(child: child),
      );
    }

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
            if (_bgOpacity > 0 &&
                bgOpacity.opacity > 0 &&
                bgOpacity.color.opacity > 0)
              Positioned.fill(
                child: ColoredBox(
                  color: bgOpacity.color.withOpacity(
                    _bgOpacity * bgOpacity.opacity,
                  ),
                ),
              ),
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

/// Defines the default border radius for certain sheet elements.
final borderRadius = BorderRadius.circular(24);

/// Configuration for the background scrim of the [DragSheet].
///
/// Allows specifying a [color] and an [opacity] level for the scrim.
class BgOpacity {
  /// The color of the background scrim.
  final Color color;

  /// The opacity of the background scrim, ranging from 0.0 (transparent) to 1.0 (opaque).
  final double opacity;

  /// Creates a [BgOpacity] configuration.
  const BgOpacity({required this.color, this.opacity = 0.5});

  /// A default [BgOpacity] configuration with black color and 0.5 opacity.
  static const BgOpacity kDefault = BgOpacity(
    color: Colors.black,
    opacity: 0.5,
  );
}
