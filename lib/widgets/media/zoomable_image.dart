import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ichan/models/models.dart';
// import 'package:ichan/pages/thread/animated_opacity_item.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/media/slideable_image.dart';

import 'package:ichan/services/my.dart' as my;

typedef DoubleClickAnimationListener = void Function();

class ZoomableImage extends StatefulWidget {
  const ZoomableImage({Key key, this.media, this.file}) : super(key: key);

  final Media media;
  final File file;

  @override
  _ZoomableImageState createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> with TickerProviderStateMixin {
  DoubleClickAnimationListener _doubleClickAnimationListener;
  AnimationController _doubleClickAnimationController;
  Animation<double> _doubleClickAnimation;
  List<double> doubleTapScales = <double>[1.0, 3.0];

  Media get media => widget.media;

  final gestureConfig = GestureConfig(
    initialScale: 1.0,
    minScale: 1.0,
    animationMinScale: 0.9,
    maxScale: 10.0,
    animationMaxScale: 11,
    speed: 1.0,
    inertialSpeed: 100.0,
    inPageView: true,
    cacheGesture: false,
    initialAlignment: InitialAlignment.center,
  );

  @override
  void initState() {
    _doubleClickAnimationController =
        AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    // keysList[widget.media.url] = null;
    _doubleClickAnimationController.dispose();
    super.dispose();
  }

  void doubleTap(ExtendedImageGestureState state) {
    final Offset pointerDownPosition = state.pointerDownPosition;
    final double begin = state.gestureDetails.totalScale;
    double end;

    //remove old
    _doubleClickAnimation?.removeListener(_doubleClickAnimationListener);

    //stop pre
    _doubleClickAnimationController.stop();

    //reset to use
    _doubleClickAnimationController.reset();

    if (begin == doubleTapScales[0]) {
      end = doubleTapScales[1];
    } else {
      end = doubleTapScales[0];
    }

    _doubleClickAnimationListener = () {
      //print(_animation.value);
      state.handleDoubleTap(
          scale: _doubleClickAnimation.value, doubleTapPosition: pointerDownPosition);
    };
    _doubleClickAnimation =
        _doubleClickAnimationController.drive(Tween<double>(begin: begin, end: end));

    _doubleClickAnimation.addListener(_doubleClickAnimationListener);

    _doubleClickAnimationController.forward();
  }

  Widget heroBuilder(Widget result, String heroTag) {
    return Hero(
      tag: heroTag,
      child: result,
      flightShuttleBuilder: (BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext) {
        final Hero hero = (flightDirection == HeroFlightDirection.pop
            ? fromHeroContext.widget
            : toHeroContext.widget) as Hero;
        return hero.child;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media == null) {
      return WillPopScope(
        onWillPop: () async => true,
        child: SlideableImage(
          child: ExtendedImage.file(
            widget.file,
            fit: BoxFit.contain,
            mode: ExtendedImageMode.gesture,
            enableSlideOutPage: true,
            filterQuality: FilterQuality.high,
            heroBuilderForSlidingPage: (Widget result) => heroBuilder(result, widget.file.path),
            initGestureConfigHandler: (state) => gestureConfig,
            onDoubleTap: doubleTap,
          ),
        ),
      );
    } else {
      final headers = System.headersForPath(media.path);

      final thumbImage = ExtendedImage.network(
        media.thumbnailUrl,
        cache: true,
        fit: BoxFit.contain,
        headers: headers,
        handleLoadingProgress: false,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return Container();
            default:
              return state.completedWidget;
          }
        },
      );

      final finalImage = ExtendedImage.network(
        media.url,
        fit: BoxFit.contain,
        cache: true,
        headers: headers,
        mode: ExtendedImageMode.gesture,
        enableSlideOutPage: true,
        filterQuality: FilterQuality.high,
        heroBuilderForSlidingPage: (Widget result) => heroBuilder(result, media.thumbnailUrl),
        onDoubleTap: doubleTap,
        initGestureConfigHandler: (state) => gestureConfig,
        handleLoadingProgress: true,
        loadStateChanged: (ExtendedImageState state) {
          final percent = (state.loadingProgress?.cumulativeBytesLoaded ?? 0.0) /
              (state.loadingProgress?.expectedTotalBytes ?? 1.0);
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  thumbImage,
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: progressLine(percent),
                  ),
                ],
              );
            case LoadState.failed:
              return Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  thumbImage,
                ],
              );
            default:
              return state.completedWidget;
          }
        },
      );

      return finalImage;
    }
  }

  Widget progressCircle(double percent) {
    return CircularProgressIndicator(
      strokeWidth: 25.0,
      value: percent,
      backgroundColor: my.theme.backgroundColor.withOpacity(0.3),
      valueColor: AlwaysStoppedAnimation<Color>(CupertinoColors.white.withOpacity(0.5)),
    );
  }

  Widget progressLine(double percent) {
    return LinearProgressIndicator(
      value: percent,
      minHeight: 1,
      backgroundColor: my.theme.inactiveColor.withOpacity(0.1),
      valueColor: AlwaysStoppedAnimation<Color>(CupertinoColors.white.withOpacity(0.5)),
    );
  }
}
