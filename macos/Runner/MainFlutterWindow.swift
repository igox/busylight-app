import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Set minimum and initial window size
    self.minSize = NSSize(width: 420, height: 820)
    self.setContentSize(NSSize(width: 420, height: 820))

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}