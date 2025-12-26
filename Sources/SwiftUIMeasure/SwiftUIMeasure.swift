import SwiftUI

// MARK: - Public API

public extension View {
    /// 标记此视图为可测量（仅 DEBUG 生效）
    @ViewBuilder
    func measurable(
        file: String = #file,
        line: Int = #line,
        column: Int = #column
    ) -> some View {
        #if DEBUG
        let id = "\(file):\(line):\(column)"
        modifier(MeasurableModifier(id: AnyHashable(id)))
        #else
        self
        #endif
    }

    /// 启用测量覆盖层（仅 DEBUG 生效）
    @ViewBuilder
    func measureOverlay(isEnabled: Binding<Bool>? = nil) -> some View {
        #if DEBUG
        let binding = isEnabled ?? .constant(true)
        modifier(MeasureOverlayModifier(isEnabled: binding))
        #else
        self
        #endif
    }
}
