import 'package:flutter/cupertino.dart';
import 'package:ichan/services/my.dart' as my;

class ActionSheet {
  const ActionSheet({
    this.child,
    this.value,
    this.text,
    this.onPressed,
    this.color,
    this.style,
  });

  final Widget child;
  final String value;
  final String text;
  final Color color;
  final TextStyle style;
  final Function onPressed;

  String get valueOrText => value ?? text.toLowerCase();
}

class Interactive {
  Interactive(this.context);
  final BuildContext context;

  static const _cancelText = 'Cancel';
  static const _deleteText = 'Delete';
  static const actions = [ActionSheet(text: "OK")];
  static const defaultTextStyle = TextStyle(fontSize: 15);

  Future<String> message({String title, String content}) async {
    return alert(actions, title: title, content: content);
  }

  Future<String> alert(List<ActionSheet> actions, {String title, String content}) async {
    return await showCupertinoDialog<String>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: title == null ? null : Text(title, style: defaultTextStyle),
          content: content == null ? null : Text(content, style: defaultTextStyle),
          actions: _buildActions(actions),
        );
      },
    );
  }

  Future<bool> modalDelete({String text, Function onConfirm}) async {
    text ??= _deleteText;
    final sheet = [
      ActionSheet(
        text: text,
        value: 'delete',
        color: my.theme.alertColor,
      ),
    ];

    return await modal(sheet) == 'delete';
  }

  Future<String> modal(List<ActionSheet> actions, {String cancelText}) async {
    cancelText ??= _cancelText;
    return await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: _buildActionSheets(actions),
          cancelButton: cancelText == null ? null : _cancelSheet(),
        );
      },
    );
  }

  Future<String> modalList(List<String> actions, {String cancelText}) async {
    final actionSheet = actions.map((e) => ActionSheet(text: e)).toList();
    return await modal(actionSheet);
  }

  Future<dynamic> modalTextField(
      {@required TextEditingController controller,
      String header = '',
      CupertinoDialogAction action}) {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: Column(
            children: [
              Text(header, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 15.0),
              CupertinoTextField(
                autofocus: true,
                keyboardAppearance: my.theme.brightness,
                textCapitalization: TextCapitalization.none,
                style: const TextStyle(fontSize: 15),
                controller: controller,
              ),
            ],
          ),
          actions: [
            Wrap(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CupertinoDialogAction(
                        child: Text("Cancel", style: TextStyle(color: my.theme.alertColor)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.text = '';
                        },
                      ),
                    ),
                    Expanded(child: action),
                  ],
                )
              ],
            )
          ],
        );
      },
    );
  }

  CupertinoActionSheetAction _cancelSheet({String text}) {
    text ??= _cancelText;

    return CupertinoActionSheetAction(
      isDefaultAction: true,
      child: Text(text),
      onPressed: () {
        return Navigator.pop(context, 'cancel');
      },
    );
  }

  TextStyle _getStyle(ActionSheet action) {
    if (action.style != null) {
      return action.style;
    } else if (action.color != null) {
      return TextStyle(color: action.color);
    }
    return null;
  }

  List<Widget> _buildActionSheets(List<ActionSheet> actions) {
    final List<Widget> result = [];

    for (final action in actions) {
      final sheet = CupertinoActionSheetAction(
        child: action.child ?? Text(action.text, style: _getStyle(action)),
        onPressed: () {
          if (action.onPressed != null) {
            action.onPressed();
          }
          return Navigator.pop(context, action.valueOrText);
        },
      );
      result.add(sheet);
    }

    return result;
  }

  List<Widget> _buildActions(List<ActionSheet> actions) {
    final List<Widget> result = [];

    for (final action in actions) {
      final sheet = CupertinoDialogAction(
        child: action.child ?? Text(action.text, style: _getStyle(action)),
        onPressed: () {
          if (action.onPressed != null) {
            action.onPressed();
          }
          return Navigator.pop(context, action.valueOrText);
        },
      );
      result.add(sheet);
    }

    return result;
  }
}
