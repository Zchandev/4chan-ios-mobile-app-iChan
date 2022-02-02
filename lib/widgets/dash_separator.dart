import 'package:flutter/cupertino.dart';
import 'package:ichan/services/my.dart' as my;

class DashSeparator extends StatelessWidget {
  const DashSeparator({
    this.height = 1,
    this.color,
    this.padding = 0.0,
    this.direction = Axis.horizontal,
  });

  final double height;
  final double padding;
  final Color color;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 10.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Container(
          margin: EdgeInsets.only(top: padding, bottom: padding),
          child: Flex(
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color ?? my.theme.primaryColor),
                ),
              );
            }),
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: direction,
          ),
        );
      },
    );
  }
}
