import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:ichan/services/consts.dart';

class BlurFilter extends StatelessWidget {
  const BlurFilter({
    Key key,
    this.child,
    this.enabled = true,
    this.withOpacity = true,
    this.sigma = 10.0,
  }) : super(key: key);

  final Widget child;
  final bool enabled;
  final bool withOpacity;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
        ),
        child: withOpacity ? Opacity(opacity: Consts.navbarOpacity, child: child) : child,
      ),
    );
  }
}
