import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let lightBackground = NSColor(
    srgbRed: CGFloat(0xFC) / 255.0,
    green: CGFloat(0xFB) / 255.0,
    blue: CGFloat(0xFA) / 255.0,
    alpha: 1.0)
  private static let darkBackground = NSColor(
    srgbRed: CGFloat(0x1E) / 255.0,
    green: CGFloat(0x1E) / 255.0,
    blue: CGFloat(0x1E) / 255.0,
    alpha: 1.0)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.minSize = NSSize(width: 900, height: 600)
    self.title = "PDFLibre"

    // 타이틀바를 앱 배경과 통합 (트래픽 라이트 영역이 Flutter 테마 색과 이어지도록)
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    // 초기값은 라이트. Flutter 쪽 WindowChromeService가 effective brightness를
    // 감지해 pdflibre/window_chrome 채널로 즉시 갱신한다.
    applyBrightness("light")

    let channel = FlutterMethodChannel(
      name: "pdflibre/window_chrome",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "setBrightness":
        guard let mode = call.arguments as? String else {
          result(FlutterError(
            code: "INVALID_ARGS",
            message: "Expected String ('light' | 'dark')",
            details: nil))
          return
        }
        DispatchQueue.main.async {
          self.applyBrightness(mode)
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  private func applyBrightness(_ mode: String) {
    if mode == "dark" {
      self.appearance = NSAppearance(named: .darkAqua)
      self.backgroundColor = MainFlutterWindow.darkBackground
    } else {
      self.appearance = NSAppearance(named: .aqua)
      self.backgroundColor = MainFlutterWindow.lightBackground
    }
  }
}
