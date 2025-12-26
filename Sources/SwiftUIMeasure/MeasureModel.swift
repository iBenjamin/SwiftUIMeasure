import SwiftUI

/// 可测量视图的身份 + 位置
struct MeasurableItem: Equatable, Sendable {
    let id: AnyHashable
    let rect: CGRect
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

/// 边缘距离 - 统一返回水平+垂直，不做分支判断
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
