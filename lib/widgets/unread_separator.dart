import 'package:flutter/material.dart';
import 'package:ichan/services/extensions.dart';
import 'package:ichan/services/my.dart' as my;

class UnreadSeparator extends StatelessWidget {
  const UnreadSeparator({
    this.height = 1,
    this.color,
    this.padding = 5.0,
    this.width = 0.75,
  });

  final double height;
  final double padding;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;

    final line = Container(
      width: screenWidth / 2 - 35,
      decoration: BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: color ?? my.theme.primaryColor, width: width),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        line,
        Text(
          "NEW",
          style: TextStyle(
            inherit: false,
            fontSize: 15.0,
            color: color ?? my.theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        line,
      ],
    );
  }
}
