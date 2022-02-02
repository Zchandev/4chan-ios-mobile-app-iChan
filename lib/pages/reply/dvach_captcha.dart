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
class DvachCaptchaPage extends StatefulWidget {
  DvachCaptchaPage(
      {Key key,
      this.captchaClickCallback,
      this.captchaSolvedCallback,
      @required this.isCaptchaVisible})
      : super(key: key);
  // WebViewController webviewController;
  InAppWebViewController webviewController;
  final Function captchaClickCallback;
  final Function captchaSolvedCallback;
  final ValueNotifier<bool> isCaptchaVisible;

  Future<String> getCaptchaResponse() async {
    return await webviewController.evaluateJavascript(
        source: 'document.getElementById("g-recaptcha-response").value') as String;
  }

  @override
  _DvachCaptchaPageState createState() => _DvachCaptchaPageState();
}

class _DvachCaptchaPageState extends State<DvachCaptchaPage> {
  static String url = '${my.makabaApi.domain}/api/captcha/recaptcha/mobile';
  bool isVisible = false;
  CaptchaStatus status = CaptchaStatus.loading;

  @override
  void initState() {
    checkCaptchaState();
    super.initState();
    // isVisible = !isIos;
    widget.isCaptchaVisible.addListener(() {
      // print('eee, val is ${widget.isCaptchaVisible.value}');
      setVisible(false);
    });
  }

  void checkCaptchaState() {
    Future.delayed(15.seconds).then((val) {
      if (status == CaptchaStatus.loading) {
        setState(() {
          status = CaptchaStatus.error;
        });
      }
    });
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
appendStyle(`$css`);

window.external = {
  notify : function() {
    window.flutter_inappwebview.callHandler('callback', 'solved').then(function(result) {});
  }
}

function apply() {
  var metaTag=document.createElement('meta');
  metaTag.name = "viewport";
  metaTag.content = "width=device-width, initial-scale=$scale, maximum-scale=$scale, user-scalable=0";
  document.getElementsByTagName('head')[0].appendChild(metaTag);

  return true;
}
apply();
""";
    // document.getElementById("rc-anchor-container").className = 'rc-anchor rc-anchor-normal rc-anchor-dark';
  }

  void setVisible(bool newVisible) {
    if (newVisible == false) {
      setState(() {
        status = CaptchaStatus.loading;
        isVisible = false;
        widget.webviewController.reload();
      });
    }
  }

  Future<void> pageFinished() async {
    widget.webviewController.evaluateJavascript(source: getEvalJs());
    if (isIos) {
      await Future.delayed(const Duration(milliseconds: 200));
    } else {
      await Future.delayed(const Duration(milliseconds: 750));
      // set state for android
      if (mounted) {
        setState(() {
          isVisible = true;
        });
      }
    }
    status = CaptchaStatus.loaded;
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
              color: my.theme.secondaryBackgroundColor,
              child: InAppWebView(
                initialUrl: url,
                // initialHeaders: {},
                initialOptions: InAppWebViewGroupOptions(
                  ios: IOSInAppWebViewOptions(
                    sharedCookiesEnabled: true,
                  ),
                  android: AndroidInAppWebViewOptions(
                    initialScale: 1,
                    useShouldInterceptRequest: true,
                  ),
                  crossPlatform: InAppWebViewOptions(
                    useOnLoadResource: true,
                    useShouldOverrideUrlLoading: true,
                    // transparentBackground: true,
                    debuggingEnabled: isDebug,
                  ),
                ),
                // ignore: missing_return
                androidShouldInterceptRequest: (controller, request) {
                  const url = "https://www.google.com/recaptcha/api2/reload";
                  if (request.url.startsWith(url)) {
                    widget.captchaClickCallback();
                  }
                },
                shouldOverrideUrlLoading: (_, request) {
                  // print('isVisible = ${isVisible}, request.url = ${request.url}');
                  if (request.url.contains('api2/bframe?hl=')) {
                    print("Contains");
                    // set state for ios
                    if (mounted) {
                      Future.delayed(1.0.seconds).then((val) {
                        if (!isVisible) {
                          setState(() {
                            isVisible = true;
                            status = CaptchaStatus.loaded;
                          });
                        }
                      });
                    }
                  }
                  if (isVisible && request.url == "about:blank") {
                    widget.captchaClickCallback();
                  }
                  return Future.value(ShouldOverrideUrlLoadingAction.ALLOW);
                },
                onWebViewCreated: (InAppWebViewController controller) {
                  widget.webviewController = controller;
                  controller.addJavaScriptHandler(
                    handlerName: "callback",
                    callback: (args) {
                      if (args[0] == 'solved') {
                        widget.captchaSolvedCallback();
                      }
                    },
                  );
                },
                onLoadStart: (InAppWebViewController controller, String url) {
                  widget.webviewController.evaluateJavascript(source: getStartJs());
                },
                onLoadStop: (InAppWebViewController controller, String url) {
                  pageFinished();
                },
                // onLoadResource: (controller, resource) {
                //   print("Resource loaded");
                // },
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
}
