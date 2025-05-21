import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class DragSheetController {
  late OverlayEntry _entry;
  late _DragSheetState _state;
  bool _isSheetShown = false;

  bool get isSheetShown => _isSheetShown;

  void show(BuildContext context, WidgetBuilder builder, {double openRatio = 0.9}) {
    if (_isSheetShown) return;
    _entry = OverlayEntry(builder: (ctx) => DragSheet(builder: builder, openRatio: openRatio, controller: this));
    Overlay.of(context, rootOverlay: true).insert(_entry);
    _isSheetShown = true;
  }

  void hide({Offset? velocity}) {
    if (_isSheetShown) {
      _state._hideSheet(velocity: velocity);
    }
  }

  void _register(_DragSheetState state) {
    _state = state;
  }

  void _onDismissed() {
    _isSheetShown = false;
    _entry.remove();
  }
}

class DragSheet extends StatefulWidget {
  final double openRatio;
  final WidgetBuilder builder;
  final DragSheetController controller;

  const DragSheet({super.key, required this.builder, required this.controller, this.openRatio = 0.9});

  @override
  _DragSheetState createState() => _DragSheetState();
}

class _DragSheetState extends State<DragSheet> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  Offset _position = Offset(0, 1); // x: 0=center, y: 1=closed
  bool _shown = false;

  double get openY => 1 - widget.openRatio;

  @override
  void initState() {
    super.initState();
    widget.controller._register(this);
    _ctrl = AnimationController.unbounded(vsync: this)..value = _position.dy;
    _showSheet();
  }

  void _showSheet() {
    setState(() {
      _shown = true;
      _position = Offset(0, 1);
    });
    final spring = SpringDescription(mass: 1, stiffness: 500, damping: 50);
    final simY = SpringSimulation(spring, _position.dy, openY, 0.0);
    _ctrl.value = _position.dy;
    _ctrl.animateWith(simY);
    _ctrl.addListener(() {
      setState(() {
        _position = Offset(_position.dx, _ctrl.value);
      });
    });
  }

  void _hideSheet({Offset? velocity}) {
    if (!_shown) return;
    _shown = false;
    widget.controller._isSheetShown = false;

    final dx = velocity?.dx ?? 0;
    final dy = velocity?.dy ?? 0;

    // Only dismiss if past a boundary AND velocity is in that direction
    Offset? direction;
    if (_position.dx < -0.3 && dx <= 0) {
      direction = Offset(-1, 0); // left
    } else if (_position.dx > 0.3 && dx >= 0) {
      direction = Offset(1, 0); // right
    } else if (_position.dy < openY - 0.1 && dy <= 0) {
      direction = Offset(0, -1); // up
    } else if (_position.dy > openY + 0.3 && dy >= 0) {
      direction = Offset(0, 1); // down
    }

    if (direction != null) {
      // Animate off screen in that direction
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
      final duration = Duration(milliseconds: 900);
      ctrl.addListener(() {
        final t = ctrl.value * duration.inMilliseconds / 1000.0;
        setState(() {
          _position = Offset(simX.x(t), simY.x(t));
        });
      });
      ctrl.animateTo(1.0, duration: duration).whenComplete(() {
        ctrl.dispose();
        widget.controller._onDismissed();
      });
    } else {
      // Not a valid dismiss, spring back
      _springBack();
    }
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

  void _springBack() {
    final spring = SpringDescription(mass: 1, stiffness: 500, damping: 50);

    // Animate X back to center
    final xCtrl = AnimationController.unbounded(vsync: this);
    xCtrl.value = _position.dx;
    final simX = SpringSimulation(spring, _position.dx, 0.0, 0.0);
    xCtrl.animateWith(simX).whenComplete(() => xCtrl.dispose());

    // Animate Y back to open position
    _ctrl.value = _position.dy;
    final simY = SpringSimulation(spring, _position.dy, openY, 0.0);
    _ctrl.animateWith(simY);

    xCtrl.addListener(() {
      setState(() {
        _position = Offset(xCtrl.value, _position.dy);
      });
    });
    _ctrl.addListener(() {
      setState(() {
        _position = Offset(_position.dx, _ctrl.value);
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final size = MediaQuery.of(ctx).size;
    final sheetHeight = size.height * widget.openRatio;
    final offsetY = size.height * _position.dy;
    final offsetX = size.width * _position.dx;

    return Stack(
      children: [
        Positioned(
          top: offsetY,
          left: offsetX,
          width: size.width,
          height: sheetHeight,
          child: GestureDetector(
            onPanUpdate: _handleDragUpdate,
            onPanEnd: _handleDragEnd,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Column(
                children: [
                  // little “grabber” bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                  ),
                  // your content
                  Expanded(child: widget.builder(ctx)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
