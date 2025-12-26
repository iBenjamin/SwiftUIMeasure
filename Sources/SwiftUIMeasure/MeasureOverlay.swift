import SwiftUI

/// 测量覆盖层 Modifier
struct MeasureOverlayModifier: ViewModifier {
    @Binding var isEnabled: Bool
    @State private var selection = MeasureSelection()

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(MeasurablePreferenceKey.self) { items in
                GeometryReader { proxy in
                    let rects = items.map { ResolvedItem(id: $0.id, rect: proxy[$0.anchor]) }
                    if isEnabled {
                        MeasureCanvas(
                            items: rects,
                            selection: $selection
                        )
                        .allowsHitTesting(true)
                    }
                }
            }
            .onChange(of: isEnabled) { _, newValue in
                if !newValue { selection.clear() }
            }
    }
}

/// 解析后的可测量项（anchor -> rect）
struct ResolvedItem {
    let id: AnyHashable
    let rect: CGRect
}

/// 测量画布：绘制可点击区域 + 测量线
struct MeasureCanvas: View {
    let items: [ResolvedItem]
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
                let result = MeasureResult.between(rectA, rectB)
                switch result {
                case .sibling(let distance):
                    drawSiblingLines(context: &context, distance: distance)
                case .parentChild(let distance):
                    drawParentChildLines(context: &context, distance: distance)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            // 找到包含点击位置的所有元素
            let hits = items.filter { $0.rect.contains(location) }
            // 选择最内层：不包含其他任何命中元素的那个
            let tapped = hits.first { candidate in
                !hits.contains { other in
                    other.id != candidate.id && candidate.rect.contains(other.rect)
                }
            }
            if let tapped {
                selection.toggle(tapped.id)
            }
        }
    }

    private func drawSiblingLines(context: inout GraphicsContext, distance: EdgeDistance) {
        let lineColor = Color.red
        let textColor = Color.white
        let bgColor = Color.red

        // 当两条线都存在时，标签需要偏移避免重叠
        let bothExist = distance.horizontal != nil && distance.vertical != nil
        let labelOffset: CGFloat = bothExist ? 12 : 0

        if let h = distance.horizontal, let line = distance.horizontalLine {
            drawMeasureLine(
                context: &context,
                from: line.start,
                to: line.end,
                label: formatDistance(h),
                lineColor: lineColor,
                textColor: textColor,
                bgColor: bgColor,
                labelOffset: CGPoint(x: 0, y: -labelOffset) // 水平线标签往上偏移
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
                bgColor: bgColor,
                labelOffset: CGPoint(x: labelOffset, y: 0) // 垂直线标签往右偏移
            )
        }
    }

    private func drawParentChildLines(context: inout GraphicsContext, distance: ParentChildDistance) {
        let lineColor = Color.orange
        let textColor = Color.white
        let bgColor = Color.orange

        // Top
        if distance.top > 0 {
            drawMeasureLine(context: &context, from: distance.topLine.start, to: distance.topLine.end,
                           label: formatDistance(distance.top), lineColor: lineColor, textColor: textColor, bgColor: bgColor)
        }
        // Bottom
        if distance.bottom > 0 {
            drawMeasureLine(context: &context, from: distance.bottomLine.start, to: distance.bottomLine.end,
                           label: formatDistance(distance.bottom), lineColor: lineColor, textColor: textColor, bgColor: bgColor)
        }
        // Left
        if distance.left > 0 {
            drawMeasureLine(context: &context, from: distance.leftLine.start, to: distance.leftLine.end,
                           label: formatDistance(distance.left), lineColor: lineColor, textColor: textColor, bgColor: bgColor)
        }
        // Right
        if distance.right > 0 {
            drawMeasureLine(context: &context, from: distance.rightLine.start, to: distance.rightLine.end,
                           label: formatDistance(distance.right), lineColor: lineColor, textColor: textColor, bgColor: bgColor)
        }
    }

    private func drawMeasureLine(
        context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        label: String,
        lineColor: Color,
        textColor: Color,
        bgColor: Color,
        labelOffset: CGPoint = .zero
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

        // 标签（带偏移）
        let midPoint = CGPoint(
            x: (start.x + end.x) / 2 + labelOffset.x,
            y: (start.y + end.y) / 2 + labelOffset.y
        )
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
