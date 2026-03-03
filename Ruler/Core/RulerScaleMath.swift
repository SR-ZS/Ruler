import CoreGraphics

enum RulerScaleMath {
    static func pointsPerUnit(pointsPerCentimeter: CGFloat, unit: RulerUnit) -> CGFloat {
        guard pointsPerCentimeter > 0 else { return 0 }
        return pointsPerCentimeter * unit.centimetersPerUnit
    }

    static func minorTickRange(
        offset: CGFloat,
        viewportStart: CGFloat,
        viewportEnd: CGFloat,
        minorStep: CGFloat
    ) -> ClosedRange<Int>? {
        guard minorStep > 0, viewportEnd >= viewportStart else { return nil }
        let firstTick = Int(floor((offset + viewportStart) / minorStep)) - 1
        let lastTick = Int(ceil((offset + viewportEnd) / minorStep)) + 1
        guard firstTick <= lastTick else { return nil }
        return firstTick...lastTick
    }

    static func majorTickRange(
        offset: CGFloat,
        viewportStart: CGFloat,
        viewportEnd: CGFloat,
        pointsPerUnit: CGFloat
    ) -> ClosedRange<Int>? {
        guard pointsPerUnit > 0, viewportEnd >= viewportStart else { return nil }
        let firstUnit = Int(floor((offset + viewportStart) / pointsPerUnit)) - 1
        let lastUnit = Int(ceil((offset + viewportEnd) / pointsPerUnit)) + 1
        guard firstUnit <= lastUnit else { return nil }
        return firstUnit...lastUnit
    }

    static func coordinateValue(viewportMid: CGFloat, offset: CGFloat, pointsPerUnit: CGFloat) -> CGFloat {
        guard pointsPerUnit > 0 else { return 0 }
        return (viewportMid + offset) / pointsPerUnit
    }
}
