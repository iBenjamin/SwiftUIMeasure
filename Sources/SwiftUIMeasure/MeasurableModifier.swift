import SwiftUI

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
            .anchorPreference(key: MeasurablePreferenceKey.self, value: .bounds) { anchor in
                [MeasurableItem(id: id, anchor: anchor)]
            }
    }
}
