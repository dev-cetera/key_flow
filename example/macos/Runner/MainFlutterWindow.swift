import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Flutter shows its controls to accessibility clients other than VoiceOver
    // (agents, automation, Accessibility Inspector) only once the window says a
    // screen reader started. Say so at launch.
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: NSNotification.Name("NSApplicationDidChangeAccessibilityEnhancedUserInterfaceNotification"),
        object: NSApp, userInfo: ["AXEnhancedUserInterface": true])
    }

    super.awakeFromNib()
  }
}
