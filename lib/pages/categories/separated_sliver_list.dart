import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:ichan/services/my.dart' as my;

class SeparatedSliverList extends StatelessWidget {
  const SeparatedSliverList({Key key, @required this.items}) : super(key: key);

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final int itemIndex = index ~/ 2;
          if (index.isEven) {
            return SizedBox(height: 55, child: items[itemIndex]);
          }
          return Divider(
            height: 1,
            color: my.theme.dividerColor,
            thickness: 1,
          );
        },
        semanticIndexCallback: (Widget widget, int localIndex) {
          return localIndex.isEven ? localIndex ~/ 2 : null;
        },
        childCount: math.max(0, items.length * 2 - 1),
      ),
    );
  }
}
