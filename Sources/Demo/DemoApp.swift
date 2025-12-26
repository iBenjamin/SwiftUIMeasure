import SwiftUI
import SwiftUIMeasure

@main
struct DemoApp: App {
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 500)
        }
        #else
        WindowGroup {
            ShakeDetectorView {
                ContentView()
            }
        }
        #endif
    }
}

struct ContentView: View {
    @State private var measureEnabled = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 顶部提示
            HStack {
                Text("SwiftUIMeasure Demo")
                    .font(.headline)
                Spacer()
                #if os(macOS)
                Text("Press M to toggle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #else
                #if targetEnvironment(simulator)
                Text("Press M to toggle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #else
                Text("Shake to toggle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #endif
                #endif
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            // 测试区域
            ZStack {
                Color.white

                VStack(spacing: 40) {
                    // 兄弟元素测试
                    HStack(spacing: 60) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .frame(width: 80, height: 80)
                            .measurable()

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                            .frame(width: 100, height: 60)
                            .measurable()
                    }

                    // 父子元素测试
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 120)
                        .measurable()
                        .overlay(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple)
                                .frame(width: 80, height: 50)
                                .measurable()
                                .padding(10)
                        }

                    HStack(spacing: 50) {
                        Text("Label A")
                            .padding(12)
                            .background(Color.yellow)
                            .cornerRadius(6)
                            .measurable()

                        Text("Label B")
                            .padding(12)
                            .background(Color.cyan)
                            .cornerRadius(6)
                            .measurable()
                    }
                }
            }
            .measureOverlay(isEnabled: $measureEnabled)
        }
        #if os(macOS)
        .focusable()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress("m") {
            measureEnabled.toggle()
            return .handled
        }
        #else
        .onReceive(NotificationCenter.default.publisher(for: .toggleMeasure)) { _ in
            measureEnabled.toggle()
        }
        #endif
    }
}

// MARK: - iOS Activation

#if os(iOS)
import UIKit

extension Notification.Name {
    static let toggleMeasure = Notification.Name("toggleMeasure")
}

/// 包装视图，处理摇晃和键盘事件
struct ShakeDetectorView<Content: View>: UIViewControllerRepresentable {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    func makeUIViewController(context: Context) -> ShakeHostingController<Content> {
        ShakeHostingController(rootView: content())
    }

    func updateUIViewController(_ uiViewController: ShakeHostingController<Content>, context: Context) {
        uiViewController.rootView = content()
    }
}

class ShakeHostingController<Content: View>: UIHostingController<Content> {
    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    // 真机：摇晃检测
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .toggleMeasure, object: nil)
        }
    }

    // 模拟器：键盘 M 键
    #if targetEnvironment(simulator)
    override var keyCommands: [UIKeyCommand]? {
        [UIKeyCommand(input: "m", modifierFlags: [], action: #selector(handleKeyM))]
    }

    @objc private func handleKeyM() {
        NotificationCenter.default.post(name: .toggleMeasure, object: nil)
    }
    #endif
}
#endif
