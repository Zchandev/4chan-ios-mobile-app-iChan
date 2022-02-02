import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ichan/services/extensions.dart';
import 'package:ichan/services/my.dart' as my;

class LoadingListPage extends StatefulWidget {
  const LoadingListPage({this.count});

  final int count;

  @override
  _LoadingListPageState createState() => _LoadingListPageState();
}

class _LoadingListPageState extends State<LoadingListPage> {
  static const boxColor = Colors.white70;

  int calcItemCount() {
    if (widget.count <= 0) {
      return 0;
    } else {
      return widget.count >= 10 ? 10 : widget.count;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listItems = Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70.0,
            height: 70.0,
            color: boxColor,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 12.0,
                  color: boxColor,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.0),
                ),
                Container(
                  width: double.infinity,
                  height: 12.0,
                  color: boxColor,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.0),
                ),
                Container(
                  width: 40.0,
                  height: 12.0,
                  color: boxColor,
                ),
              ],
            ),
          )
        ],
      ),
    );

    return CupertinoPageScaffold(
      child: Container(
        height: context.screenHeight,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.white,
                highlightColor: Colors.orange,
                enabled: true,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => Divider(color: my.theme.dividerColor),
                  itemBuilder: (_, __) {
                    return listItems;
                  },
                  itemCount: calcItemCount(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
