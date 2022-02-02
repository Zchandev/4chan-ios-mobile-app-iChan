import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    var flutter_native_splash = 1
    UIApplication.shared.isStatusBarHidden = false

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let homeButtonChannel = FlutterMethodChannel(name: "zchandev/homebutton",
                                                 binaryMessenger: controller.binaryMessenger)
    homeButtonChannel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
        // Note: this method is invoked on the UI thread.
        guard call.method == "hasHomeButton" else {
            result(FlutterMethodNotImplemented)
            return
        }
        self?.checkHomeButton(result: result)
    })

    
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func checkHomeButton(result: FlutterResult) {
        var isBottom: Bool {
            if #available(iOS 11.0, *), let keyWindow = UIApplication.shared.keyWindow, keyWindow.safeAreaInsets.bottom > 0 {
                return true
            }
            return false
        }
        return result(!isBottom)
    }
    

    
    
}
