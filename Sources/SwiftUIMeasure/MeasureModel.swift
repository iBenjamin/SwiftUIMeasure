import SwiftUI

/// 可测量视图的身份 + 位置锚点
struct MeasurableItem: Equatable {
    let id: AnyHashable
    let anchor: Anchor<CGRect>

    static func == (lhs: MeasurableItem, rhs: MeasurableItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// 选中状态 - 数组 + FIFO，消除 first/second 的特殊情况
struct MeasureSelection {
    private var items: [AnyHashable] = []

    mutating func toggle(_ id: AnyHashable) {
        if let index = items.firstIndex(of: id) {
            items.remove(at: index)
        } else {
            if items.count >= 2 {
                items.removeFirst()
            }
            items.append(id)
        }
    }

    func contains(_ id: AnyHashable) -> Bool {
        items.contains(id)
    }

    var pair: (AnyHashable, AnyHashable)? {
        guard items.count == 2 else { return nil }
        return (items[0], items[1])
    }

    mutating func clear() {
        items.removeAll()
    }
}

/// 测量结果 - 兄弟元素或父子元素
enum MeasureResult {
    case sibling(EdgeDistance)
    case parentChild(ParentChildDistance)

    static func between(_ a: CGRect, _ b: CGRect) -> MeasureResult {
        // 检查父子关系：一个完全包含另一个
        if a.contains(b) {
            return .parentChild(ParentChildDistance.calculate(parent: a, child: b))
        }
        if b.contains(a) {
            return .parentChild(ParentChildDistance.calculate(parent: b, child: a))
        }
        return .sibling(EdgeDistance.between(a, b))
    }
}

/// 父子元素的四边距离
struct ParentChildDistance {
    let top: CGFloat
    let bottom: CGFloat
    let left: CGFloat
    let right: CGFloat

    let topLine: (start: CGPoint, end: CGPoint)
    let bottomLine: (start: CGPoint, end: CGPoint)
    let leftLine: (start: CGPoint, end: CGPoint)
    let rightLine: (start: CGPoint, end: CGPoint)

    static func calculate(parent: CGRect, child: CGRect) -> ParentChildDistance {
        let top = child.minY - parent.minY
        let bottom = parent.maxY - child.maxY
        let left = child.minX - parent.minX
        let right = parent.maxX - child.maxX

        let childMidX = child.midX
        let childMidY = child.midY

        return ParentChildDistance(
            top: top,
            bottom: bottom,
            left: left,
            right: right,
            topLine: (CGPoint(x: childMidX, y: parent.minY), CGPoint(x: childMidX, y: child.minY)),
            bottomLine: (CGPoint(x: childMidX, y: child.maxY), CGPoint(x: childMidX, y: parent.maxY)),
            leftLine: (CGPoint(x: parent.minX, y: childMidY), CGPoint(x: child.minX, y: childMidY)),
            rightLine: (CGPoint(x: child.maxX, y: childMidY), CGPoint(x: parent.maxX, y: childMidY))
        )
    }
}

/// 兄弟元素边缘距离 - 统一返回水平+垂直，不做分支判断
struct EdgeDistance {
    let horizontal: CGFloat?
    let vertical: CGFloat?

    /// 水平测量线的端点（如果有水平间距）
    let horizontalLine: (start: CGPoint, end: CGPoint)?
    /// 垂直测量线的端点（如果有垂直间距）
    let verticalLine: (start: CGPoint, end: CGPoint)?

    static func between(_ a: CGRect, _ b: CGRect) -> EdgeDistance {
        // 水平距离：最近边缘
        let hResult: (distance: CGFloat, line: (CGPoint, CGPoint))? = {
            let gap1 = b.minX - a.maxX  // a 在左
            let gap2 = a.minX - b.maxX  // b 在左

            // 计算垂直方向的重叠中点，用于画线
            let overlapMinY = max(a.minY, b.minY)
            let overlapMaxY = min(a.maxY, b.maxY)
            let midY = (overlapMinY + overlapMaxY) / 2

            if gap1 > 0 {
                return (gap1, (CGPoint(x: a.maxX, y: midY), CGPoint(x: b.minX, y: midY)))
            }
            if gap2 > 0 {
                return (gap2, (CGPoint(x: b.maxX, y: midY), CGPoint(x: a.minX, y: midY)))
            }
            return nil
        }()

        // 垂直距离：最近边缘
        let vResult: (distance: CGFloat, line: (CGPoint, CGPoint))? = {
            let gap1 = b.minY - a.maxY  // a 在上
            let gap2 = a.minY - b.maxY  // b 在上

            // 计算水平方向的重叠中点
            let overlapMinX = max(a.minX, b.minX)
            let overlapMaxX = min(a.maxX, b.maxX)
            let midX = (overlapMinX + overlapMaxX) / 2

            if gap1 > 0 {
                return (gap1, (CGPoint(x: midX, y: a.maxY), CGPoint(x: midX, y: b.minY)))
            }
            if gap2 > 0 {
                return (gap2, (CGPoint(x: midX, y: b.maxY), CGPoint(x: midX, y: a.minY)))
            }
            return nil
        }()

        return EdgeDistance(
            horizontal: hResult?.distance,
            vertical: vResult?.distance,
            horizontalLine: hResult?.line,
            verticalLine: vResult?.line
        )
    }
}
