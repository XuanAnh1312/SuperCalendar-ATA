import Flutter
import UIKit
import EventKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let eventStore = EKEventStore()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    FlutterMethodChannel(name: "supercalendar/app_settings", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "openNotificationSettings" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let address: String
        if #available(iOS 16.0, *) {
          address = UIApplication.openNotificationSettingsURLString
        } else {
          address = UIApplication.openSettingsURLString
        }
        guard let url = URL(string: address) else { result(false); return }
        UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
      }
    FlutterMethodChannel(name: "supercalendar/system_calendar", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard let self = self else { result(false); return }
        switch call.method {
        case "hasPermission": result(self.hasCalendarAccess)
        case "requestPermission":
          let completion: (Bool, Error?) -> Void = { granted, _ in
            DispatchQueue.main.async { result(granted) }
          }
          if #available(iOS 17.0, *) {
            self.eventStore.requestFullAccessToEvents(completion: completion)
          } else {
            self.eventStore.requestAccess(to: .event, completion: completion)
          }
        case "events":
          guard self.hasCalendarAccess,
            let args = call.arguments as? [String: Any],
            let from = args["from"] as? NSNumber,
            let to = args["to"] as? NSNumber else { result([]); return }
          let start = Date(timeIntervalSince1970: from.doubleValue / 1000)
          let end = Date(timeIntervalSince1970: to.doubleValue / 1000)
          guard end > start else { result([]); return }
          let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
          let rows: [[String: Any]] = self.eventStore.events(matching: predicate).map { event in
            [
              "id": event.eventIdentifier ?? event.calendarItemIdentifier,
              "title": event.title ?? "", "description": event.notes ?? "",
              "begin": Int64(event.startDate.timeIntervalSince1970 * 1000),
              "end": Int64(event.endDate.timeIntervalSince1970 * 1000),
              "allDay": event.isAllDay ? 1 : 0, "location": event.location ?? "",
              "calendar": event.calendar.title,
              "calendarId": event.calendar.calendarIdentifier
            ]
          }
          result(rows)
        default: result(FlutterMethodNotImplemented)
        }
      }
  }

  private var hasCalendarAccess: Bool {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) { return status == .fullAccess }
    return status == .authorized
  }
}
