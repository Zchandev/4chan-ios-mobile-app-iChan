import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter/services.dart';

class SlideableImage extends StatelessWidget {
  const SlideableImage({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExtendedImageSlidePage(
      child: child,
      slideAxis: SlideAxis.vertical,
      slideType: SlideType.onlyImage,
      slideScaleHandler: (offset, {state}) => defaultSlideScaleHandler(
        offset: offset,
        pageSize: state.pageSize,
        pageGestureAxis: SlideAxis.vertical,
      ),
      slidePageBackgroundHandler: (offset, pageSize) =>
          defaultSlidePageBackgroundHandler(
        offset: offset,
        pageSize: pageSize,
        color: CupertinoColors.black.withOpacity(0.5),
        pageGestureAxis: SlideAxis.vertical,
      ),
    );
  }
}
