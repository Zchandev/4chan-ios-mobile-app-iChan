import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/home_page.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/shimmer_widget.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    my.contextTools.init(context);

    return HeaderNavbar(
        backGesture: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Consts.sidePadding * 2),
          child: Column(
            children: [
              const SizedBox(width: 50, height: 50),
              const ShimmerLoader(text: "Welcome. Again."),
              const SizedBox(height: 70),
              const Text("What's your primary board?"),
              const SizedBox(width: 20, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 50.0),
                    child: const Text("2ch"),
                    color: my.theme.primaryColor,
                    onPressed: () {
                      Haptic.mediumImpact();
                      my.prefs.put('platforms', [Platform.dvach]);
                      my.categoryBloc.selectedPlatform = Platform.dvach;
                      my.prefs.put('dvach_enabled', true);
                      Routz.of(context).toPage(const HomePage(), replace: true);
                    },
                  ),
                  const SizedBox(width: 10, height: 10),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 45.0),
                    child: const Text("4chan"),
                    color: my.theme.quoteColor,
                    onPressed: () {
                      Haptic.mediumImpact();
                      my.prefs.put('platforms', [Platform.fourchan]);
                      my.prefs.put('fourchan_enabled', true);
                      my.categoryBloc.selectedPlatform = Platform.fourchan;
                      Routz.of(context).toPage(const HomePage(), replace: true);
                      my.prefs.put('theme', 'dark_green');
                      my.themeManager.updateTheme();
                    },
                  ),
                ],
              )
            ],
          ),
        ));
  }
}
