import Cocoa
import FlutterMacOS
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.igox.busylight_buddy/autostart",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isEnabled":
        if #available(macOS 13.0, *) {
          result(SMAppService.mainApp.status == .enabled)
        } else {
          // Fallback for older macOS: check LaunchAgent plist existence
          let plist = self.launchAgentURL()
          result(FileManager.default.fileExists(atPath: plist.path))
        }

      case "setEnabled":
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        if #available(macOS 13.0, *) {
          do {
            if enabled {
              try SMAppService.mainApp.register()
            } else {
              try SMAppService.mainApp.unregister()
            }
            result(nil)
          } catch {
            result(FlutterError(code: "AUTOSTART_ERROR", message: error.localizedDescription, details: nil))
          }
        } else {
          // Fallback: write/remove LaunchAgent plist
          self.setLaunchAgentLegacy(enabled: enabled)
          result(nil)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  // ── Legacy LaunchAgent fallback (macOS < 13) ────────────────────────────

  private func launchAgentURL() -> URL {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home
      .appendingPathComponent("Library/LaunchAgents")
      .appendingPathComponent("com.igox.busylight_buddy.plist")
  }

  private func setLaunchAgentLegacy(enabled: Bool) {
    let url = launchAgentURL()
    if enabled {
      let execURL = Bundle.main.executableURL!.path
      let plist: [String: Any] = [
        "Label": "com.igox.busylight_buddy",
        "ProgramArguments": [execURL],
        "RunAtLoad": true,
        "KeepAlive": false,
      ]
      try? (plist as NSDictionary).write(to: url)
    } else {
      try? FileManager.default.removeItem(at: url)
    }
  }
}