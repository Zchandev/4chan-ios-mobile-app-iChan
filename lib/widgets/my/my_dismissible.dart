import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

enum _FlingGestureKind { none, forward, reverse }

const Curve _kResizeTimeCurve = Interval(0.4, 1.0, curve: Curves.ease);
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kDismissThreshold = 0.4;

class _DismissibleClipper extends CustomClipper<Rect> {
  _DismissibleClipper({
    @required this.axis,
    @required this.moveAnimation,
  })  : assert(axis != null),
        assert(moveAnimation != null),
        super(reclip: moveAnimation);

  final Axis axis;
  final Animation<Offset> moveAnimation;

  @override
  Rect getClip(Size size) {
    assert(axis != null);
    switch (axis) {
      case Axis.horizontal:
        final double offset = moveAnimation.value.dx * size.width;
        if (offset < 0)
          return Rect.fromLTRB(
              size.width + offset, 0.0, size.width, size.height);
        return Rect.fromLTRB(0.0, 0.0, offset, size.height);
      case Axis.vertical:
        final double offset = moveAnimation.value.dy * size.height;
        if (offset < 0)
          return Rect.fromLTRB(
              0.0, size.height + offset, size.width, size.height);
        return Rect.fromLTRB(0.0, 0.0, size.width, offset);
    }
    return null;
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_DismissibleClipper oldClipper) {
    return oldClipper.axis != axis ||
        oldClipper.moveAnimation.value != moveAnimation.value;
  }
}

class MyDismissible extends StatefulWidget {
  const MyDismissible({
    @required Key key,
    @required this.child,
    this.enabledListener,
    this.background,
    this.secondaryBackground,
    this.confirmDismiss,
    this.onResize,
    this.onDismissed,
    this.onDragStart,
    this.onDragEnd,
    this.direction = DismissDirection.horizontal,
    this.resizeDuration = const Duration(milliseconds: 300),
    this.dismissThresholds = const <DismissDirection, double>{},
    this.movementDuration = const Duration(milliseconds: 200),
    this.crossAxisEndOffset = 0.0,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(key != null),
        assert(secondaryBackground == null || background != null),
        assert(dragStartBehavior != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  final ValueNotifier<bool> enabledListener;

  /// A widget that is stacked behind the child. If secondaryBackground is also
  /// specified then this widget only appears when the child has been dragged
  /// down or to the right.
  final Widget background;

  /// A widget that is stacked behind the child and is exposed when the child
  /// has been dragged up or to the left. It may only be specified when background
  /// has also been specified.
  final Widget secondaryBackground;

  /// Gives the app an opportunity to confirm or veto a pending dismissal.
  ///
  /// If the returned Future<bool> completes true, then this widget will be
  /// dismissed, otherwise it will be moved back to its original location.
  ///
  /// If the returned Future<bool> completes to false or null the [onResize]
  /// and [onDismissed] callbacks will not run.
  final ConfirmDismissCallback confirmDismiss;

  /// Called when the widget changes size (i.e., when contracting before being dismissed).
  final VoidCallback onResize;

  final Function onDragStart;
  final Function onDragEnd;

  /// Called when the widget has been dismissed, after finishing resizing.
  final DismissDirectionCallback onDismissed;

  /// The direction in which the widget can be dismissed.
  final DismissDirection direction;

  /// The amount of time the widget will spend contracting before [onDismissed] is called.
  ///
  /// If null, the widget will not contract and [onDismissed] will be called
  /// immediately after the widget is dismissed.
  final Duration resizeDuration;

  /// The offset threshold the item has to be dragged in order to be considered
  /// dismissed.
  ///
  /// Represented as a fraction, e.g. if it is 0.4 (the default), then the item
  /// has to be dragged at least 40% towards one direction to be considered
  /// dismissed. Clients can define different thresholds for each dismiss
  /// direction.
  ///
  /// Flinging is treated as being equivalent to dragging almost to 1.0, so
  /// flinging can dismiss an item past any threshold less than 1.0.
  ///
  /// Setting a threshold of 1.0 (or greater) prevents a drag in the given
  /// [DismissDirection] even if it would be allowed by the [direction]
  /// property.
  ///
  /// See also:
  ///
  ///  * [direction], which controls the directions in which the items can
  ///    be dismissed.
  final Map<DismissDirection, double> dismissThresholds;

  /// Defines the duration for card to dismiss or to come back to original position if not dismissed.
  final Duration movementDuration;

  /// Defines the end offset across the main axis after the card is dismissed.
  ///
  /// If non-zero value is given then widget moves in cross direction depending on whether
  /// it is positive or negative.
  final double crossAxisEndOffset;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], the drag gesture used to dismiss a
  /// dismissible will begin upon the detection of a drag gesture. If set to
  /// [DragStartBehavior.down] it will begin when a down event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  @override
  _MyDismissibleState createState() => _MyDismissibleState();
}

class _MyDismissibleState extends State<MyDismissible>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();

    // widget.enabledListener.addListener(() {
    //   print("Setting state to $_isEnabled");
    //   setState(() {
    //     _isEnabled = widget.enabledListener.value;
    //   });
    // });

    _moveController =
        AnimationController(duration: widget.movementDuration, vsync: this)
          ..addStatusListener(_handleDismissStatusChanged);
    _updateMoveAnimation();
  }

  AnimationController _moveController;
  Animation<Offset> _moveAnimation;

  AnimationController _resizeController;
  Animation<double> _resizeAnimation;

  double _dragExtent = 0.0;
  bool _dragUnderway = false;
  Size _sizePriorToCollapse;

  bool _isEnabled = true;

  void enable() {
    print("Enabling");
    setState(() {
      _isEnabled = true;
    });
  }

  void disable() {
    print("Disabling");
    setState(() {
      _isEnabled = false;
    });
  }

  @override
  bool get wantKeepAlive =>
      _moveController?.isAnimating == true ||
      _resizeController?.isAnimating == true;

  @override
  void dispose() {
    _moveController.dispose();
    _resizeController?.dispose();
    super.dispose();
  }

  bool get _directionIsXAxis {
    return widget.direction == DismissDirection.horizontal ||
        widget.direction == DismissDirection.endToStart ||
        widget.direction == DismissDirection.startToEnd;
  }

  DismissDirection _extentToDirection(double extent) {
    if (extent == 0.0) {
      return null;
    }
    if (_directionIsXAxis) {
      switch (Directionality.of(context)) {
        case TextDirection.rtl:
          return extent < 0
              ? DismissDirection.startToEnd
              : DismissDirection.endToStart;
        case TextDirection.ltr:
          return extent > 0
              ? DismissDirection.startToEnd
              : DismissDirection.endToStart;
      }
      assert(false);
      return null;
    }
    return extent > 0 ? DismissDirection.down : DismissDirection.up;
  }

  DismissDirection get _dismissDirection => _extentToDirection(_dragExtent);

  bool get _isActive {
    return _dragUnderway || _moveController.isAnimating;
  }

  double get _overallDragAxisExtent {
    final Size size = context.size;
    return _directionIsXAxis ? size.width : size.height;
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.onDragStart != null) {
      widget.onDragStart();
    }
    _dragUnderway = true;
    if (_moveController.isAnimating) {
      _dragExtent =
          _moveController.value * _overallDragAxisExtent * _dragExtent.sign;
      _moveController.stop();
    } else {
      _dragExtent = 0.0;
      _moveController.value = 0.0;
    }

    setState(() {
      _updateMoveAnimation();
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isActive || _moveController.isAnimating) {
      return;
    }

    final double delta = details.primaryDelta;
    final double oldDragExtent = _dragExtent;
    switch (widget.direction) {
      case DismissDirection.horizontal:
      case DismissDirection.vertical:
        _dragExtent += delta;
        break;

      case DismissDirection.up:
        if (_dragExtent + delta < 0) {
          _dragExtent += delta;
        }
        break;

      case DismissDirection.down:
        if (_dragExtent + delta > 0) {
          _dragExtent += delta;
        }
        break;

      case DismissDirection.endToStart:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta > 0) {
              _dragExtent += delta;
            }
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta < 0) {
              _dragExtent += delta;
            }
            break;
        }
        break;

      case DismissDirection.startToEnd:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta < 0) {
              _dragExtent += delta;
            }
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta > 0) {
              _dragExtent += delta;
            }
            break;
        }
        break;
    }
    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        _updateMoveAnimation();
      });
    }
    if (!_moveController.isAnimating) {
      _moveController.value = _dragExtent.abs() / _overallDragAxisExtent;
    }
  }

  void _updateMoveAnimation() {
    final double end = _dragExtent.sign;
    _moveAnimation = _moveController.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: _directionIsXAxis
            ? Offset(end, widget.crossAxisEndOffset)
            : Offset(widget.crossAxisEndOffset, end),
      ),
    );
  }

  _FlingGestureKind _describeFlingGesture(Velocity velocity) {
    assert(widget.direction != null);
    if (_dragExtent == 0.0) {
      // If it was a fling, then it was a fling that was let loose at the exact
      // middle of the range (i.e. when there's no displacement). In that case,
      // we assume that the user meant to fling it back to the center, as
      // opposed to having wanted to drag it out one way, then fling it past the
      // center and into and out the other side.
      return _FlingGestureKind.none;
    }
    final double vx = velocity.pixelsPerSecond.dx;
    final double vy = velocity.pixelsPerSecond.dy;
    DismissDirection flingDirection;
    // Verify that the fling is in the generally right direction and fast enough.
    if (_directionIsXAxis) {
      if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta ||
          vx.abs() < _kMinFlingVelocity) {
        return _FlingGestureKind.none;
      }
      assert(vx != 0.0);
      flingDirection = _extentToDirection(vx);
    } else {
      if (vy.abs() - vx.abs() < _kMinFlingVelocityDelta ||
          vy.abs() < _kMinFlingVelocity) {
        return _FlingGestureKind.none;
      }
      assert(vy != 0.0);
      flingDirection = _extentToDirection(vy);
    }
    assert(_dismissDirection != null);
    if (flingDirection == _dismissDirection) {
      return _FlingGestureKind.forward;
    }
    return _FlingGestureKind.reverse;
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (!_isActive || _moveController.isAnimating) {
      return;
    }
    if (widget.onDragEnd != null) {
      final _result = widget.onDragEnd();
      if (_result == false) {
        return;
      }
      widget.onDragEnd();
    }
    _dragUnderway = false;

    if (_moveController.isCompleted &&
        await _confirmStartResizeAnimation() == true) {
      _startResizeAnimation();
      return;
    }
    final double flingVelocity = _directionIsXAxis
        ? details.velocity.pixelsPerSecond.dx
        : details.velocity.pixelsPerSecond.dy;
    switch (_describeFlingGesture(details.velocity)) {
      case _FlingGestureKind.forward:
        assert(_dragExtent != 0.0);
        assert(!_moveController.isDismissed);
        if ((widget.dismissThresholds[_dismissDirection] ??
                _kDismissThreshold) >=
            1.0) {
          _moveController.reverse();
          break;
        }
        _dragExtent = flingVelocity.sign;
        _moveController.fling(
            velocity: flingVelocity.abs() * _kFlingVelocityScale);
        break;
      case _FlingGestureKind.reverse:
        assert(_dragExtent != 0.0);
        assert(!_moveController.isDismissed);
        _dragExtent = flingVelocity.sign;
        _moveController.fling(
            velocity: -flingVelocity.abs() * _kFlingVelocityScale);
        break;
      case _FlingGestureKind.none:
        if (!_moveController.isDismissed) {
          // we already know it's not completed, we check that above
          if (_moveController.value >
              (widget.dismissThresholds[_dismissDirection] ??
                  _kDismissThreshold)) {
            _moveController.forward();
          } else {
            _moveController.reverse();
          }
        }
        break;
    }
  }

  Future<void> _handleDismissStatusChanged(AnimationStatus status) async {
    if (status == AnimationStatus.completed && !_dragUnderway) {
      if (await _confirmStartResizeAnimation() == true)
        _startResizeAnimation();
      else
        _moveController.reverse();
    }
    updateKeepAlive();
  }

  Future<bool> _confirmStartResizeAnimation() async {
    if (widget.confirmDismiss != null) {
      final DismissDirection direction = _dismissDirection;
      assert(direction != null);
      return widget.confirmDismiss(direction);
    }
    return true;
  }

  void _startResizeAnimation() {
    assert(_moveController != null);
    assert(_moveController.isCompleted);
    assert(_resizeController == null);
    assert(_sizePriorToCollapse == null);
    if (widget.resizeDuration == null) {
      if (widget.onDismissed != null) {
        final DismissDirection direction = _dismissDirection;
        assert(direction != null);
        widget.onDismissed(direction);
      }
    } else {
      _resizeController =
          AnimationController(duration: widget.resizeDuration, vsync: this)
            ..addListener(_handleResizeProgressChanged)
            ..addStatusListener((AnimationStatus status) => updateKeepAlive());
      _resizeController.forward();
      setState(() {
        _sizePriorToCollapse = context.size;
        _resizeAnimation = _resizeController
            .drive(
              CurveTween(curve: _kResizeTimeCurve),
            )
            .drive(
              Tween<double>(
                begin: 1.0,
                end: 0.0,
              ),
            );
      });
    }
  }

  void _handleResizeProgressChanged() {
    if (_resizeController.isCompleted) {
      if (widget.onDismissed != null) {
        final DismissDirection direction = _dismissDirection;
        assert(direction != null);
        widget.onDismissed(direction);
      }
    } else {
      if (widget.onResize != null) {
        widget.onResize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.

    assert(!_directionIsXAxis || debugCheckHasDirectionality(context));

    Widget background = widget.background;
    if (widget.secondaryBackground != null) {
      final DismissDirection direction = _dismissDirection;
      if (direction == DismissDirection.endToStart ||
          direction == DismissDirection.up)
        background = widget.secondaryBackground;
    }

    if (_resizeAnimation != null) {
      // we've been dragged aside, and are now resizing.
      assert(() {
        if (_resizeAnimation.status != AnimationStatus.forward) {
          assert(_resizeAnimation.status == AnimationStatus.completed);
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                'A dismissed Dismissible widget is still part of the tree.'),
            ErrorHint(
                'Make sure to implement the onDismissed handler and to immediately remove the Dismissible '
                'widget from the application once that handler has fired.')
          ]);
        }
        return true;
      }());

      return SizeTransition(
        sizeFactor: _resizeAnimation,
        axis: _directionIsXAxis ? Axis.vertical : Axis.horizontal,
        child: SizedBox(
          width: _sizePriorToCollapse.width,
          height: _sizePriorToCollapse.height,
          child: background,
        ),
      );
    }

    Widget content = SlideTransition(
      position: _moveAnimation,
      child: widget.child,
    );

    if (background != null) {
      content = Stack(children: <Widget>[
        if (!_moveAnimation.isDismissed)
          Positioned.fill(
            child: ClipRect(
              clipper: _DismissibleClipper(
                axis: _directionIsXAxis ? Axis.horizontal : Axis.vertical,
                moveAnimation: _moveAnimation,
              ),
              child: background,
            ),
          ),
        content,
      ]);
    }
    if (_isEnabled) {
      return GestureDetector(
        onHorizontalDragStart: _directionIsXAxis ? _handleDragStart : null,
        onHorizontalDragUpdate: _directionIsXAxis ? _handleDragUpdate : null,
        onHorizontalDragEnd: _directionIsXAxis ? _handleDragEnd : null,
        onVerticalDragStart: _directionIsXAxis ? null : _handleDragStart,
        onVerticalDragUpdate: _directionIsXAxis ? null : _handleDragUpdate,
        onVerticalDragEnd: _directionIsXAxis ? null : _handleDragEnd,
        behavior: HitTestBehavior.opaque,
        child: content,
        dragStartBehavior: widget.dragStartBehavior,
      );
    } else {
      return content;
    }
    // We are not resizing but we may be being dragging in widget.direction.
  }
}
