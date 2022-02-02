import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/favorites_page.dart';
import 'package:ichan/services/consts.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/services/extensions.dart';
import 'package:ichan/services/routz.dart';
import 'package:ichan/widgets/my/my_cupertino_page_scaffold.dart';

class HeaderNavbar extends StatelessWidget {
  const HeaderNavbar({
    Key key,
    this.trailing,
    this.middle,
    this.middleText,
    this.previousPageTitle,
    this.backgroundColor,
    this.onStatusBarTap,
    this.backGesture = true,
    this.transparent = false,
    @required this.child,
  }) : super(key: key);

  final Widget child;
  final Widget middle;
  final Widget trailing;
  final Function onStatusBarTap;
  final Color backgroundColor;
  final String middleText;
  final String previousPageTitle;
  final bool backGesture;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final myBackgroundColor = backgroundColor ?? my.theme.backgroundColor;

    final navBackgroundColor = my.theme.navbarBackgroundColor.withOpacity(Consts.navbarOpacity);

    return MyCupertinoPageScaffold(
      backgroundColor: myBackgroundColor,
      onStatusBarTap: onStatusBarTap,
      navigationBar: CupertinoNavigationBar(
        brightness: my.theme.menuBrightness,
        actionsForegroundColor: my.theme.navbarFontColor,
        border: Border(bottom: BorderSide(color: my.theme.navBorderColor)),
        backgroundColor: navBackgroundColor,
        transitionBetweenRoutes: false,
        automaticallyImplyLeading: true,
        automaticallyImplyMiddle: true,
        previousPageTitle: previousPageTitle,
        middle: setMiddleText(),
        trailing: trailing,
      ),
      child: SafeArea(
        top: transparent == false,
        bottom: false,
        left: false,
        right: false,
        child: childWithGesture(context),
      ),
    );
  }

  Widget childWithGesture(BuildContext context) {
    if (!backGesture) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity >= Consts.backGestureVelocity) {
          Navigator.maybePop(context);
        } else if (details.primaryVelocity <= -1 * Consts.backGestureVelocity) {
          Routz(context).toPage(const FavoritesPage());
        }
      },
      child: Container(
        height: context.screenHeight,
        child: child,
      ),
    );
  }

  Widget setMiddleText() {
    if (middle != null) {
      return middle;
    } else if (middleText != null) {
      return Text(
        middleText,
        style: TextStyle(color: my.theme.navbarFontColor),
      );
    }
    return null;
  }
}
