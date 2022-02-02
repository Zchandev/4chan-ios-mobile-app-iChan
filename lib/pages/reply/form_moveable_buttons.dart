import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ichan/pages/reply/quote_button.dart';
import 'package:ichan/pages/reply/tag_button.dart';
import 'package:ichan/services/my.dart' as my;

class FormMoveableButtons extends StatelessWidget {
  const FormMoveableButtons({Key key, this.controller, this.position}) : super(key: key);

  final TextEditingController controller;
  final String position;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: my.prefs.box.listenable(keys: ['markup_on_bottom']),
      builder: (context, box, child) {
        final isBottom = my.prefs.getBool('markup_on_bottom');
        if (isBottom ? position != "bottom" : position != "top") {
          return Container();
        }
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity >= 200) {
              if (!isBottom) {
                my.prefs.put('markup_on_bottom', true);
              }
            } else if (details.primaryVelocity <= -200) {
              if (isBottom) {
                my.prefs.put('markup_on_bottom', false);
              }
            }
          },
          child: Padding(
            padding: EdgeInsets.only(top: isBottom ? 5.0 : 0.0, bottom: isBottom ? 0.0 : 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    flex: 3,
                    child: TagButton(
                      controller: controller,
                      child: Text("B",
                          style: TextStyle(
                            fontSize: 22,
                            color: my.theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          )),
                      tagName: "b",
                    )),
                Expanded(
                    flex: 3,
                    child: TagButton(
                        controller: controller,
                        child: Text("I",
                            style: TextStyle(
                              fontSize: 22,
                              color: my.theme.primaryColor,
                              fontStyle: FontStyle.italic,
                            )),
                        tagName: "i")),
                Expanded(
                  flex: 3,
                  child: TagButton(
                      controller: controller,
                      child: Text("U",
                          style: TextStyle(
                            fontSize: 22,
                            color: my.theme.primaryColor,
                            decoration: TextDecoration.underline,
                          )),
                      tagName: "u"),
                ),
                Expanded(
                    flex: 3,
                    child: TagButton(
                        controller: controller,
                        child: Text("S",
                            style: TextStyle(
                              fontSize: 22,
                              color: my.theme.primaryColor,
                              decoration: TextDecoration.lineThrough,
                            )),
                        tagName: "s")),
                Expanded(
                    flex: 4, child: QuoteButton(controller: controller, text: ">Q", tagName: "q")),
                Expanded(
                    flex: 4,
                    child: TagButton(controller: controller, text: "SP", tagName: "spoiler")),
                Expanded(
                    flex: 3, child: TagButton(controller: controller, text: "A^", tagName: "sup")),
                Expanded(
                    flex: 3, child: TagButton(controller: controller, text: " A_", tagName: "sub")),
              ],
            ),
          ),
        );
      },
    );
  }
}
