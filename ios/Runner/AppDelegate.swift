import UIKit
import Flutter
import flutter_foreground_task
import native_geofence

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

            // Used by plugin: native_geofence
    NativeGeofencePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // 1. Register flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // 2. Register background callbacks
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback(registerPlugins)
    
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
