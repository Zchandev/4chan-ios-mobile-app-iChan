import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ichan/services/my.dart' as my;

class ShimmerLoader extends StatefulWidget {
  const ShimmerLoader({Key key, this.text = "Loading...", this.debugInfo = "loading..."})
      : super(key: key);

  final String text;
  final String debugInfo;

  @override
  ShimmerLoaderState createState() => ShimmerLoaderState();
}

class ShimmerLoaderState extends State<ShimmerLoader> with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInQuad)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
        // if (status == AnimationStatus.completed) {
        // controller.reverse();
        // } else  }
      });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedShimmer(
      animation: animation,
      // text: isDebug  ? widget.debugInfo : widget.text,
      text: widget.text,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class AnimatedShimmer extends AnimatedWidget {
  const AnimatedShimmer({Key key, Animation<double> animation, this.text})
      : super(key: key, listenable: animation);

  // Make the Tweens static because they don't change.
  static final _opacityTween = Tween<double>(begin: 0.0, end: 1.0);
  final String text;

  @override
  Widget build(BuildContext context) {
    final shimmer = Shimmer.fromColors(
      baseColor: my.theme.foregroundBrightColor,
      highlightColor: my.theme.linkColor,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 35.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final animation = listenable as Animation<double>;
    return Center(
      child: Opacity(
        opacity: _opacityTween.evaluate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: shimmer,
        ),
      ),
    );
  }
}
