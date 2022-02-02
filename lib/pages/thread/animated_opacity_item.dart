import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

// First post item
class AnimatedOpacityItem extends StatefulWidget {
  const AnimatedOpacityItem({
    Key key,
    this.child,
    this.enabled = true,
    this.reverse = false,
    this.loadedAt = 0,
    this.delay = 0.0,
    this.onEnd,
    this.runPostFrame = true,
  }) : super(key: key);

  final Widget child;
  final bool enabled;
  final bool reverse;
  final bool runPostFrame;
  final double delay;
  final int loadedAt;
  final Function onEnd;

  @override
  AnimatedOpacityItemState createState() => AnimatedOpacityItemState();
}

class AnimatedOpacityItemState extends State<AnimatedOpacityItem> {
  double opacity = 0.0;
  double targetOpacity = 1.0;
  bool enabled = false;
  static const animationDiff = 1000;

  @override
  void initState() {
    enabled = widget.enabled;
    if (widget.loadedAt > 0) {
      final diff = DateTime.now().millisecondsSinceEpoch - widget.loadedAt;
      if (diff >= animationDiff) {
        enabled = false;
      }
    }

    if (widget.reverse) {
      opacity = 1;
      targetOpacity = 0.0;
    }

    if (enabled) {
      startAnimation();
    }
    super.initState();
  }

  void startAnimation() async {
    if (widget.delay >= 0) {
      await Future.delayed(widget.delay.seconds);
    }

    if (widget.runPostFrame) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            opacity = targetOpacity;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          opacity = targetOpacity;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return widget.child;
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: my.prefs.getBool("fast_animation") ? 0.2.seconds : 0.3.seconds,
      child: widget.child,
      onEnd: () => widget.onEnd == null ? null : widget.onEnd(),
    );
  }
}
