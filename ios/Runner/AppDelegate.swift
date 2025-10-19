import UIKit
import Flutter
// REMOVED: flutter_foreground_task - causes App Store rejection
// REMOVED: native_geofence - causes App Store rejection

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // REMOVED: Native geofence registration - causes App Store rejection
    
    // Register flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // REMOVED: Foreground task callbacks - causes App Store rejection
    
    // 3. Hook notification delegate (FlutterAppDelegate already conforms)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Notification Handling
  
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Display alert & sound when a notification arrives in-app
    completionHandler([.alert, .sound])
  }
}

// MARK: - Background plugin registration bridge

fileprivate func registerPlugins(registry: FlutterPluginRegistry) {
  GeneratedPluginRegistrant.register(with: registry)
}
