import 'package:flutter/cupertino.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/shimmer_widget.dart';

class TapToReload extends StatelessWidget {
  TapToReload({
    Key key,
    this.message,
    this.onTap,
    this.enabled = true,
  }) : super(key: key);

  final Function onTap;
  final String message;
  final bool enabled;
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  static const defaultMessage = 'Error.';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
          onTap: () async {
            if (onTap != null && enabled) {
              isLoading.value = true;
              await Future.delayed(2.seconds);
              onTap();
              isLoading.value = false;
            }
          },
          child: ValueListenableBuilder(
              valueListenable: isLoading,
              builder: (context, val, snapshot) {
                if (val == true) {
                  return const ShimmerLoader();
                } else {
                  return Center(
                      child: Text(
                    '${message ?? defaultMessage}${enabled ? '\nTap to reload.' : ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: my.theme.primaryColor,
                      fontSize: Consts.errorLoadingTextSize,
                    ),
                  ));
                }
              })),
    );
  }
}
