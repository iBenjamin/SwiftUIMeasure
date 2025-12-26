import SwiftUI

/// 测量坐标空间名称
let measureCoordinateSpace = "com.iBenjamin.swiftui.measure"

/// PreferenceKey 收集所有可测量视图的位置
struct MeasurablePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [MeasurableItem] = []

    static func reduce(value: inout [MeasurableItem], nextValue: () -> [MeasurableItem]) {
        value.append(contentsOf: nextValue())
    }
}

/// 标记视图为可测量
struct MeasurableModifier: ViewModifier {
    let id: AnyHashable

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .named(measureCoordinateSpace))
                    Color.clear
                        .preference(key: MeasurablePreferenceKey.self, value: [MeasurableItem(id: id, rect: rect)])
                }
            }
    }
}
