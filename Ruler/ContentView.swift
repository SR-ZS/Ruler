//
//  ContentView.swift
//  Ruler
//
//  UIKit implementation for iOS 12+ support.
//

import UIKit

final class RulerViewController: UIViewController {
    private let rulerView = RulerCanvasView()
    private let unitControl = UISegmentedControl(items: ["cm", "inch"])
    private let hintLabel = UILabel()

    private var panStartOffset: CGPoint = .zero

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        rulerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rulerView)

        NSLayoutConstraint.activate([
            rulerView.topAnchor.constraint(equalTo: view.topAnchor),
            rulerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rulerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rulerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupTopControls()
        setupGestures()
        applyCurrentScale()
    }

    private func setupTopControls() {
        unitControl.translatesAutoresizingMaskIntoConstraints = false
        unitControl.selectedSegmentIndex = 0
        unitControl.backgroundColor = UIColor(white: 0.18, alpha: 0.95)
        if #available(iOS 13.0, *) {
            unitControl.selectedSegmentTintColor = UIColor(white: 0.95, alpha: 1)
            unitControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
            unitControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        } else {
            unitControl.tintColor = UIColor.white
        }
        unitControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.text = "Drag to move ruler • Double tap to reset"
        hintLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        hintLabel.textColor = UIColor(white: 0.75, alpha: 0.9)
        hintLabel.textAlignment = .right

        view.addSubview(unitControl)
        view.addSubview(hintLabel)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            unitControl.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            unitControl.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -10),
            unitControl.widthAnchor.constraint(equalToConstant: 140),

            hintLabel.centerYAnchor.constraint(equalTo: unitControl.centerYAnchor),
            hintLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 68),
            hintLabel.trailingAnchor.constraint(equalTo: unitControl.leadingAnchor, constant: -8)
        ])
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(resetOffset))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyCurrentScale()
    }

    private func applyCurrentScale() {
        let model = DeviceScaleModel.current
        rulerView.deviceName = model.displayName
        rulerView.pointsPerCentimeter = model.pointsPerCentimeter
    }

    @objc private func unitChanged() {
        rulerView.unitStyle = unitControl.selectedSegmentIndex == 0 ? .centimeter : .inch
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panStartOffset = rulerView.contentOffset
        case .changed, .ended:
            let t = gesture.translation(in: view)
            rulerView.contentOffset = CGPoint(x: panStartOffset.x - t.x, y: panStartOffset.y - t.y)
        default:
            break
        }
    }

    @objc private func resetOffset() {
        rulerView.contentOffset = .zero
    }
}

private final class RulerCanvasView: UIView {
    enum UnitStyle {
        case centimeter
        case inch

        var title: String {
            switch self {
            case .centimeter: return "cm"
            case .inch: return "in"
            }
        }

        var subdivisions: Int {
            switch self {
            case .centimeter: return 10
            case .inch: return 16
            }
        }
    }

    var pointsPerCentimeter: CGFloat = 72 { didSet { setNeedsDisplay() } }
    var deviceName: String = "iPhone" { didSet { setNeedsDisplay() } }
    var unitStyle: UnitStyle = .centimeter { didSet { setNeedsDisplay() } }
    var contentOffset: CGPoint = .zero { didSet { setNeedsDisplay() } }

    private let rulerThickness: CGFloat = 56

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), pointsPerCentimeter > 0 else { return }

        UIColor.black.setFill()
        ctx.fill(rect)

        drawRulerBackground(in: ctx, rect: rect)
        drawHorizontalScale(in: ctx, rect: rect)
        drawVerticalScale(in: ctx, rect: rect)
        drawCrosshair(in: ctx, rect: rect)
        drawCenterReadout(in: rect)
        drawWatermark(in: rect)
    }

    private var pointsPerUnit: CGFloat {
        switch unitStyle {
        case .centimeter:
            return pointsPerCentimeter
        case .inch:
            return pointsPerCentimeter * 2.54
        }
    }

    private func drawRulerBackground(in ctx: CGContext, rect: CGRect) {
        let bg = UIColor(white: 0.10, alpha: 1)
        bg.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: rect.width, height: rulerThickness))
        ctx.fill(CGRect(x: 0, y: 0, width: rulerThickness, height: rect.height))

        UIColor(white: 0.24, alpha: 1).setStroke()
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 0, y: rulerThickness))
        ctx.addLine(to: CGPoint(x: rect.width, y: rulerThickness))
        ctx.move(to: CGPoint(x: rulerThickness, y: 0))
        ctx.addLine(to: CGPoint(x: rulerThickness, y: rect.height))
        ctx.strokePath()
    }

    private func drawHorizontalScale(in ctx: CGContext, rect: CGRect) {
        let startX = rulerThickness
        let endX = rect.width
        let subdivisions = unitStyle.subdivisions
        let minor = pointsPerUnit / CGFloat(subdivisions)

        UIColor.white.withAlphaComponent(0.95).setStroke()
        ctx.setLineWidth(1)

        let firstTick = Int(floor((contentOffset.x + startX) / minor)) - 1
        let lastTick = Int(ceil((contentOffset.x + endX) / minor)) + 1

        for tick in firstTick...lastTick {
            let x = CGFloat(tick) * minor - contentOffset.x
            guard x >= startX - minor, x <= endX + minor else { continue }

            let tickLength: CGFloat
            if tick % subdivisions == 0 {
                tickLength = 28
            } else if tick % (subdivisions / 2) == 0 {
                tickLength = 20
            } else {
                tickLength = 12
            }

            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: tickLength))
        }
        ctx.strokePath()

        let majorStart = Int(floor((contentOffset.x + startX) / pointsPerUnit)) - 1
        let majorEnd = Int(ceil((contentOffset.x + endX) / pointsPerUnit)) + 1
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.92)
        ]

        for unit in majorStart...majorEnd {
            let x = CGFloat(unit) * pointsPerUnit - contentOffset.x
            guard x >= startX - pointsPerUnit, x <= endX + pointsPerUnit else { continue }
            let text = "\(unit)" as NSString
            let size = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: x - size.width / 2, y: 33), withAttributes: attrs)
        }
    }

    private func drawVerticalScale(in ctx: CGContext, rect: CGRect) {
        let startY = rulerThickness
        let endY = rect.height
        let subdivisions = unitStyle.subdivisions
        let minor = pointsPerUnit / CGFloat(subdivisions)

        UIColor.white.withAlphaComponent(0.95).setStroke()
        ctx.setLineWidth(1)

        let firstTick = Int(floor((contentOffset.y + startY) / minor)) - 1
        let lastTick = Int(ceil((contentOffset.y + endY) / minor)) + 1

        for tick in firstTick...lastTick {
            let y = CGFloat(tick) * minor - contentOffset.y
            guard y >= startY - minor, y <= endY + minor else { continue }

            let tickLength: CGFloat
            if tick % subdivisions == 0 {
                tickLength = 28
            } else if tick % (subdivisions / 2) == 0 {
                tickLength = 20
            } else {
                tickLength = 12
            }

            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: tickLength, y: y))
        }
        ctx.strokePath()

        let majorStart = Int(floor((contentOffset.y + startY) / pointsPerUnit)) - 1
        let majorEnd = Int(ceil((contentOffset.y + endY) / pointsPerUnit)) + 1
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.92)
        ]

        for unit in majorStart...majorEnd {
            let y = CGFloat(unit) * pointsPerUnit - contentOffset.y
            guard y >= startY - pointsPerUnit, y <= endY + pointsPerUnit else { continue }
            let text = "\(unit)" as NSString
            let size = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: 32, y: y - size.height / 2), withAttributes: attrs)
        }
    }

    private func drawCrosshair(in ctx: CGContext, rect: CGRect) {
        let cross = CGPoint(x: rect.midX, y: rect.midY)

        UIColor.systemGreen.withAlphaComponent(0.9).setStroke()
        ctx.setLineWidth(1)

        ctx.move(to: CGPoint(x: rulerThickness, y: cross.y))
        ctx.addLine(to: CGPoint(x: rect.width, y: cross.y))
        ctx.move(to: CGPoint(x: cross.x, y: rulerThickness))
        ctx.addLine(to: CGPoint(x: cross.x, y: rect.height))
        ctx.strokePath()

        UIColor.systemGreen.withAlphaComponent(0.95).setFill()
        ctx.fillEllipse(in: CGRect(x: cross.x - 3, y: cross.y - 3, width: 6, height: 6))
    }

    private func drawCenterReadout(in rect: CGRect) {
        let originX = (rect.midX + contentOffset.x) / pointsPerUnit
        let originY = (rect.midY + contentOffset.y) / pointsPerUnit

        let text = String(format: "X %.2f %@   Y %.2f %@", originX, unitStyle.title, originY, unitStyle.title)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: UIColor.systemGreen.withAlphaComponent(0.95)
        ]

        let label = text as NSString
        let size = label.size(withAttributes: attrs)
        label.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rulerThickness + 12), withAttributes: attrs)
    }

    private func drawWatermark(in rect: CGRect) {
        let text = deviceName as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 30, weight: .medium),
            .foregroundColor: UIColor(white: 0.65, alpha: 0.24)
        ]
        let size = text.size(withAttributes: attrs)
        text.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attrs)
    }
}

private struct DeviceScaleModel {
    let displayName: String
    let ppi: CGFloat

    var pointsPerCentimeter: CGFloat {
        let pixelsPerCentimeter = ppi / 2.54
        return pixelsPerCentimeter / UIScreen.main.scale
    }

    static var current: DeviceScaleModel {
        let identifier = DeviceIdentifier.current
        let ppi = CGFloat(ppiByIdentifier[identifier] ?? 460)
        let name = modelNameByIdentifier[identifier] ?? identifier
        return DeviceScaleModel(displayName: name, ppi: ppi)
    }

    private static let modelNameByIdentifier: [String: String] = [
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e"
    ]

    private static let ppiByIdentifier: [String: Int] = [
        "iPhone15,2": 460,
        "iPhone15,3": 460,
        "iPhone15,4": 460,
        "iPhone15,5": 460,
        "iPhone16,1": 460,
        "iPhone16,2": 460,
        "iPhone17,1": 460,
        "iPhone17,2": 460,
        "iPhone17,3": 460,
        "iPhone17,4": 460,
        "iPhone17,5": 460
    ]
}

private enum DeviceIdentifier {
    static var current: String {
#if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iPhone16,1"
#else
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce(into: "") { output, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            output.append(String(UnicodeScalar(UInt8(value))))
        }
#endif
    }
}
