import SwiftUI

/// 测量覆盖层 Modifier
struct MeasureOverlayModifier: ViewModifier {
    @Binding var isEnabled: Bool
    @State private var selection = MeasureSelection()
    @State private var items: [MeasurableItem] = []

    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: measureCoordinateSpace)
            .onPreferenceChange(MeasurablePreferenceKey.self) { items = $0 }
            .overlay {
                if isEnabled {
                    MeasureCanvas(
                        items: items,
                        selection: $selection
                    )
                    .allowsHitTesting(true)
                }
            }
            .onChange(of: isEnabled) { _, newValue in
                if !newValue { selection.clear() }
            }
    }
}

/// 测量画布：绘制可点击区域 + 测量线
struct MeasureCanvas: View {
    let items: [MeasurableItem]
    @Binding var selection: MeasureSelection

    var body: some View {
        Canvas { context, size in
            // 绘制高亮框
            for item in items {
                let isSelected = selection.contains(item.id)
                let rect = item.rect

                if isSelected {
                    context.fill(Path(rect), with: .color(.blue.opacity(0.3)))
                }
                context.stroke(
                    Path(rect),
                    with: .color(.blue.opacity(isSelected ? 1 : 0.5)),
                    lineWidth: isSelected ? 2 : 1
                )
            }

            // 绘制测量线
            if let pair = selection.pair,
               let rectA = items.first(where: { $0.id == pair.0 })?.rect,
               let rectB = items.first(where: { $0.id == pair.1 })?.rect {
                let distance = EdgeDistance.between(rectA, rectB)
                drawMeasurementLines(context: &context, distance: distance)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            if let tapped = items.first(where: { $0.rect.contains(location) }) {
                selection.toggle(tapped.id)
            }
        }
    }

    private func drawMeasurementLines(context: inout GraphicsContext, distance: EdgeDistance) {
        let lineColor = Color.red
        let textColor = Color.white
        let bgColor = Color.red

        if let h = distance.horizontal, let line = distance.horizontalLine {
            drawMeasureLine(
                context: &context,
                from: line.start,
                to: line.end,
                label: formatDistance(h),
                lineColor: lineColor,
                textColor: textColor,
                bgColor: bgColor
            )
        }

        if let v = distance.vertical, let line = distance.verticalLine {
            drawMeasureLine(
                context: &context,
                from: line.start,
                to: line.end,
                label: formatDistance(v),
                lineColor: lineColor,
                textColor: textColor,
                bgColor: bgColor
            )
        }
    }

    private func drawMeasureLine(
        context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        label: String,
        lineColor: Color,
        textColor: Color,
        bgColor: Color
    ) {
        // 主线
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(lineColor), lineWidth: 1)

        // 端点标记
        let isHorizontal = abs(end.y - start.y) < abs(end.x - start.x)
        drawCap(context: &context, at: start, isHorizontal: isHorizontal, color: lineColor)
        drawCap(context: &context, at: end, isHorizontal: isHorizontal, color: lineColor)

        // 标签
        let midPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        drawLabel(context: &context, text: label, at: midPoint, textColor: textColor, bgColor: bgColor)
    }

    private func drawCap(context: inout GraphicsContext, at point: CGPoint, isHorizontal: Bool, color: Color) {
        let size: CGFloat = 6
        var path = Path()
        if isHorizontal {
            path.move(to: CGPoint(x: point.x, y: point.y - size / 2))
            path.addLine(to: CGPoint(x: point.x, y: point.y + size / 2))
        } else {
            path.move(to: CGPoint(x: point.x - size / 2, y: point.y))
            path.addLine(to: CGPoint(x: point.x + size / 2, y: point.y))
        }
        context.stroke(path, with: .color(color), lineWidth: 1)
    }

    private func drawLabel(context: inout GraphicsContext, text: String, at point: CGPoint, textColor: Color, bgColor: Color) {
        let text = Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(textColor)

        let resolved = context.resolve(text)
        let textSize = resolved.measure(in: CGSize(width: 100, height: 30))

        let padding: CGFloat = 4
        let bgRect = CGRect(
            x: point.x - textSize.width / 2 - padding,
            y: point.y - textSize.height / 2 - padding / 2,
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )

        context.fill(Path(roundedRect: bgRect, cornerRadius: 3), with: .color(bgColor))
        context.draw(resolved, at: point, anchor: .center)
    }

    private func formatDistance(_ value: CGFloat) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
