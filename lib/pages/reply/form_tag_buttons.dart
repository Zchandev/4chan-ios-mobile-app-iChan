import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/reply/quote_button.dart';
import 'package:ichan/pages/reply/tag_button.dart';

class FormTagButtonsRow extends StatelessWidget {
  const FormTagButtonsRow({Key key, @required this.controller}) : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(flex: 3, child: TagButton(controller: controller, text: "B", tagName: "b")),
        Expanded(flex: 3, child: TagButton(controller: controller, text: "I", tagName: "i")),
        Expanded(flex: 3, child: TagButton(controller: controller, text: "U", tagName: "u")),
        Expanded(flex: 3, child: TagButton(controller: controller, text: "S", tagName: "s")),
        Expanded(flex: 4, child: QuoteButton(controller: controller, text: ">Q", tagName: "q")),
        Expanded(flex: 4, child: TagButton(controller: controller, text: "SP", tagName: "spoiler")),
        Expanded(flex: 3, child: TagButton(controller: controller, text: "A^", tagName: "sup")),
        Expanded(flex: 3, child: TagButton(controller: controller, text: " A_", tagName: "sub")),
      ],
    );
  }
}
