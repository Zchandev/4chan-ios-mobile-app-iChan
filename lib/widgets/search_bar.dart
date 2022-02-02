import 'package:flutter/cupertino.dart';
import 'package:ichan/services/my.dart' as my;

class SearchBar extends StatelessWidget {
  const SearchBar(
      {Key key,
      this.controller,
      this.onChanged,
      this.onSubmitted,
      this.autofocus = false,
      this.focusNode,
      this.placeholder})
      : super(key: key);

  final TextEditingController controller;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  final String placeholder;
  final bool autofocus;

  static const fontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      key: key,
      autofocus: autofocus,
      focusNode: focusNode,
      controller: controller,
      toolbarOptions: const ToolbarOptions(copy: true, paste: true, selectAll: true, cut: true),
      clearButtonMode: OverlayVisibilityMode.editing,
      prefix: const Padding(
        padding: EdgeInsets.only(left: 12.0, bottom: 2.0),
        child: Icon(
          CupertinoIcons.search,
          size: fontSize,
          color: CupertinoColors.opaqueSeparator,
        ),
      ),
      placeholder: placeholder,
      placeholderStyle: TextStyle(
        fontSize: fontSize,
        color: my.theme.placeholderColor,
      ),
      style: const TextStyle(
        color: CupertinoColors.systemGrey,
        fontSize: fontSize,
      ),
      decoration: BoxDecoration(
        color: my.theme.threadBackgroundColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      onChanged: (val) {
        if (onChanged != null) {
          onChanged(val);
        }
      },
      onSubmitted: (val) {
        if (onSubmitted != null) {
          onSubmitted(val);
        }
      },
      minLines: 1,
      maxLines: 1,
    );
  }
}
