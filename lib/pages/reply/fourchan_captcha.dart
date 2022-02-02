import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ichan/services/exports.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ichan/services/my.dart' as my;

enum CaptchaStatus {
  loading,
  loaded,
  error,
}

// ignore: must_be_immutable
class FourchanCaptchaPage extends StatefulWidget {
  FourchanCaptchaPage({
    Key key,
    this.captchaClickCallback,
    this.captchaSolvedCallback,
    @required this.isCaptchaVisible,
  }) : super(key: key);
  InAppWebViewController webviewController;
  final Function captchaClickCallback;
  final Function captchaSolvedCallback;
  final ValueNotifier<bool> isCaptchaVisible;

  Future<String> getCaptchaResponse() async {
    return await webviewController.evaluateJavascript(
        source: 'document.getElementById("g-recaptcha-response").value') as String;
  }

  @override
  _FourchanCaptchaPageState createState() => _FourchanCaptchaPageState();
}

class _FourchanCaptchaPageState extends State<FourchanCaptchaPage> {
  static String captchaUrl = "https://boards.4chan.org/b";
  bool isVisible = false;
  CaptchaStatus status = CaptchaStatus.loading;
  final themeColor = my.theme.isDark ? 'dark' : 'light';

  @override
  void initState() {
    checkCaptchaState();
    super.initState();
    widget.isCaptchaVisible.addListener(() {
      setVisible(false);
    });
  }

  void checkCaptchaState() {
    Future.delayed(15.seconds).then((val) {
      if (mounted && status == CaptchaStatus.loading) {
        setState(() {
          status = CaptchaStatus.error;
        });
      }
    });
  }

  void setVisible(bool newVisible) {
    if (mounted && newVisible == false) {
      setState(() {
        status = CaptchaStatus.loading;
        isVisible = false;
        print("reloading");
        widget.webviewController.reload();
      });
    }
  }

  Future<void> pageFinished() async {
    widget.webviewController.evaluateJavascript(source: getEvalJs());
    if (isIos) {
      await Future.delayed(const Duration(milliseconds: 200));
    } else if (mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey("captcha"),
      children: [
        Opacity(
            opacity: isVisible ? 1.0 : 0.0,
            child: Container(
              height: isVisible ? 590 : (isIos ? 0 : 1),
              width: isVisible ? double.infinity : (isIos ? 0 : 1),
              color: my.theme.backgroundColor,
              child: InAppWebView(
                initialUrl: captchaUrl,
                initialOptions: InAppWebViewGroupOptions(
                  ios: IOSInAppWebViewOptions(
                    sharedCookiesEnabled: true,
                  ),
                  android: AndroidInAppWebViewOptions(
                    initialScale: 1,
                    useShouldInterceptRequest: true,
                  ),
                  crossPlatform: InAppWebViewOptions(
                    // useOnLoadResource: true,
                    useShouldOverrideUrlLoading: true,
                    // transparentBackground: true,
                    debuggingEnabled: isDebug,
                  ),
                ),
                // ignore: missing_return
                androidShouldInterceptRequest: (controller, request) {
                  if (isVisible &&
                      request.url.startsWith('https://www.google.com/recaptcha/api2/reload?')) {
                    widget.captchaClickCallback();
                  }
                },
                shouldOverrideUrlLoading: (_, request) {
                  if (isVisible && request.url == "about:blank") {
                    print("Captcha click for ios");
                    widget.captchaClickCallback();
                  }

                  return Future.value(ShouldOverrideUrlLoadingAction.ALLOW);
                },
                onWebViewCreated: (InAppWebViewController controller) {
                  widget.webviewController = controller;
                  controller.addJavaScriptHandler(
                    handlerName: "callback",
                    callback: (args) {
                      print(args);
                      if (args[0] == "loaded") {
                        print("Loaded in...");
                        Future.delayed(1.0.seconds).then((val) {
                          print("Now");
                          setState(() {
                            isVisible = true;
                            status = CaptchaStatus.loaded;
                          });
                        });
                      } else if (args[0] == 'solved') {
                        widget.captchaSolvedCallback();
                      }
                    },
                  );
                },
                onLoadStop: (InAppWebViewController controller, String url) {
                  pageFinished();
                },
              ),
            )),
        if (isVisible == false && status == CaptchaStatus.loading) ...[
          Container(
            color: my.theme.backgroundColor,
            child: Container(
              // key: const ValueKey("loader"),
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: Shimmer.fromColors(
                baseColor: CupertinoColors.white,
                highlightColor: my.theme.primaryColor,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  height: 74,
                  width: 300,
                  child: Container(),
                ),
              ),
            ),
          )
        ],
        if (isVisible == false && status == CaptchaStatus.error) ...[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              checkCaptchaState();
              widget.webviewController.reload();
              setState(() {
                status = CaptchaStatus.loading;
              });
            },
            child: Container(
              height: 74,
              width: 300,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(left: 8.0, top: 8.0),
              decoration: BoxDecoration(
                border: Border.all(color: my.theme.primaryColor),
                borderRadius: BorderRadius.circular(3.0),
              ),
              child: Text(
                "Error. Tap to reload.",
                style: TextStyle(
                  color: my.theme.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        ]
      ],
    );
  }

  String getStartJs() {
    return """
document.body.style.backgroundColor = "${my.theme.captchaBackground}";
    """;
  }

  String getEvalJs() {
    final scale = my.contextTools.isVerySmallHeight ? "0.73" : "1.0";
    final String css = """
body { background-color: ${my.theme.captchaBackground} !important;} 

body > div { border: 0px !important; } 
.g-recaptcha-bubble-arrow { display: none !important; }

body > div, body > div > div { 
  position: absolute !important; 
  left: 0 !important; 
  margin: 0 !important; 
  top: 0px !important; 
  padding-top: 7px; 
}""";

    return """
appendStyle = function (content) {
  style = document.createElement('STYLE');
  style.type = 'text/css';
  style.appendChild(document.createTextNode(content));
  document.head.appendChild(style);
}

function apply() {
  var metaTag=document.createElement('meta');
  metaTag.name = "viewport";
  metaTag.content = "width=device-width, initial-scale=$scale, maximum-scale=$scale, user-scalable=0";
  document.getElementsByTagName('head')[0].appendChild(metaTag);

  return true;
}

document.body.className = '';
document.body.style.background = '${my.theme.captchaBackground}'
document.body.style.display = "none";

var loadJS = function(url, implementationCode, location){
    var scriptTag = document.createElement('script');
    scriptTag.src = url;

    scriptTag.onload = implementationCode;
    scriptTag.onreadystatechange = implementationCode;

    location.appendChild(scriptTag);
};
var test = function(){};

var onloadCallback = function() {
  window.flutter_inappwebview.callHandler('callback', 'loaded').then(function(result) {
});
  };
 var verifyCallback = function(response) {
        window.flutter_inappwebview.callHandler('callback', 'solved', response).then(function(result) {
          });
      };
loadJS('https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit', test, document.body);

document.body.innerHTML = '<div id="g"></g>';
document.body.style.display = "block";
appendStyle(`$css`);
apply();

grecaptcha.render('g', {
          'sitekey' : '6Ldp2bsSAAAAAAJ5uyx_lx34lJeEpTLVkP5k04qc',
          'callback' : verifyCallback,
          'theme' : '$themeColor'
        })
""";
  }
}
