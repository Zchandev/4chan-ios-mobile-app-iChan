import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute({
    this.page,
    this.settings,
    this.title,
    this.duration,
    this.opaque,
  }) : super(
          settings: settings,
          transitionDuration: duration ?? const Duration(milliseconds: 300),
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

  final Widget page;
  final RouteSettings settings;

  final String title;

  final Duration duration;

  final bool opaque;
}
