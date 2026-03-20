import Cocoa
import FlutterMacOS
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {

  var statusItem: NSStatusItem?

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.igox.busylight_buddy/autostart",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {

      case "isEnabled":
        if #available(macOS 13.0, *) {
          result(SMAppService.mainApp.status == .enabled)
        } else {
          let plist = self?.launchAgentURL()
          result(FileManager.default.fileExists(atPath: plist?.path ?? ""))
        }

      case "setEnabled":
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        // Register/unregister autostart
        if #available(macOS 13.0, *) {
          do {
            if enabled {
              try SMAppService.mainApp.register()
            } else {
              try SMAppService.mainApp.unregister()
            }
          } catch {
            result(FlutterError(code: "AUTOSTART_ERROR", message: error.localizedDescription, details: nil))
            return
          }
        } else {
          self?.setLaunchAgentLegacy(enabled: enabled)
        }

        // Toggle dock icon and menu bar extra
        if enabled {
          self?.setupMenuBarExtra()
          NSApp.setActivationPolicy(.accessory) // hide from dock
        } else {
          self?.removeMenuBarExtra()
          NSApp.setActivationPolicy(.regular)   // show in dock
        }

        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)

    // Restore menu bar extra on launch if autostart was previously enabled
    let isAutostart: Bool
    if #available(macOS 13.0, *) {
      isAutostart = SMAppService.mainApp.status == .enabled
    } else {
      isAutostart = FileManager.default.fileExists(atPath: launchAgentURL().path)
    }
    if isAutostart {
      setupMenuBarExtra()
      NSApp.setActivationPolicy(.accessory)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // When in menu bar mode, closing the window should not quit the app
    return statusItem == nil
  }

  // ── Menu bar extra ──────────────────────────────────────────────────────

  func setupMenuBarExtra() {
    guard statusItem == nil else { return }
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = statusItem?.button {
      // Use the app icon scaled to menu bar size
      button.image = NSImage(named: NSImage.Name("AppIcon"))
      button.image?.size = NSSize(width: 18, height: 18)
      button.image?.isTemplate = false
      button.action = #selector(statusItemClicked)
      button.target = self
    }
    // Right-click menu
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Show BusyLight Buddy", action: #selector(showApp), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    statusItem?.menu = menu
  }

  func removeMenuBarExtra() {
    if let item = statusItem {
      NSStatusBar.system.removeStatusItem(item)
      statusItem = nil
    }
  }

  @objc func statusItemClicked() {
    showApp()
  }

  @objc func showApp() {
    NSApp.activate(ignoringOtherApps: true)
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
  }

  @objc func quitApp() {
    removeMenuBarExtra()
    NSApp.terminate(nil)
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