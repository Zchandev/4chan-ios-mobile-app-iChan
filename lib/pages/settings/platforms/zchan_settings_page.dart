import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/pages/settings/platforms_links_page.dart';
import 'package:ichan/widgets/header_navbar.dart';

class ZchanSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HeaderNavbar(
      previousPageTitle: PlatformsLinksPage.header,
      middleText: "Zchan",
      child: Center(
        child: Container(
          width: 350.0,
          alignment: Alignment.center,
          child: const Text(
            "Invite only. No access.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
