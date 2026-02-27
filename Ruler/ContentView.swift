//
//  ContentView.swift
//  Ruler
//
//  UIKit implementation for iOS 12+ support.
//

import UIKit

final class RulerViewController: UIViewController {
    private let horizontalRuler = HorizontalRulerView()
    private let verticalRuler = VerticalRulerView()
    private let watermarkLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        horizontalRuler.translatesAutoresizingMaskIntoConstraints = false
        verticalRuler.translatesAutoresizingMaskIntoConstraints = false

        watermarkLabel.translatesAutoresizingMaskIntoConstraints = false
        watermarkLabel.textColor = UIColor(white: 0.7, alpha: 0.45)
        watermarkLabel.font = UIFont.systemFont(ofSize: 34, weight: .medium)
        watermarkLabel.adjustsFontSizeToFitWidth = true
        watermarkLabel.minimumScaleFactor = 0.55
        watermarkLabel.textAlignment = .center
        watermarkLabel.text = DeviceScaleModel.current.displayName

        view.addSubview(horizontalRuler)
        view.addSubview(verticalRuler)
        view.addSubview(watermarkLabel)

        NSLayoutConstraint.activate([
            horizontalRuler.topAnchor.constraint(equalTo: view.topAnchor),
            horizontalRuler.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            horizontalRuler.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            horizontalRuler.heightAnchor.constraint(equalToConstant: 56),

            verticalRuler.topAnchor.constraint(equalTo: view.topAnchor),
            verticalRuler.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            verticalRuler.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            verticalRuler.widthAnchor.constraint(equalToConstant: 56),

            watermarkLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            watermarkLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            watermarkLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            watermarkLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        applyScale()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyScale()
    }

    private func applyScale() {
        let ppm = DeviceScaleModel.current.pointsPerCentimeter
        horizontalRuler.pointsPerCentimeter = ppm
        verticalRuler.pointsPerCentimeter = ppm
    }
}

private final class HorizontalRulerView: UIView {
    var pointsPerCentimeter: CGFloat = 72 { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), pointsPerCentimeter > 0 else { return }

        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.95).cgColor)
        ctx.setLineWidth(1)

        let minorSpacing = pointsPerCentimeter / 10
        let tickCount = Int(rect.width / minorSpacing)

        for tick in 0...tickCount {
            let x = CGFloat(tick) * minorSpacing
            let tickLength: CGFloat
            if tick % 10 == 0 {
                tickLength = 28
            } else if tick % 5 == 0 {
                tickLength = 20
            } else {
                tickLength = 12
            }

            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: tickLength))
        }
        ctx.strokePath()

        let units = Int(rect.width / pointsPerCentimeter)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: min(18, rect.height * 0.33), weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.92)
        ]

        for mark in 0...units {
            let text = "\(mark)" as NSString
            let size = text.size(withAttributes: attrs)
            let x = CGFloat(mark) * pointsPerCentimeter - (size.width / 2)
            let y: CGFloat = 30
            text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        }
    }
}

private final class VerticalRulerView: UIView {
    var pointsPerCentimeter: CGFloat = 72 { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), pointsPerCentimeter > 0 else { return }

        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.95).cgColor)
        ctx.setLineWidth(1)

        let minorSpacing = pointsPerCentimeter / 10
        let tickCount = Int(rect.height / minorSpacing)

        for tick in 0...tickCount {
            let y = CGFloat(tick) * minorSpacing
            let tickLength: CGFloat
            if tick % 10 == 0 {
                tickLength = 28
            } else if tick % 5 == 0 {
                tickLength = 20
            } else {
                tickLength = 12
            }

            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: tickLength, y: y))
        }
        ctx.strokePath()

        let units = Int(rect.height / pointsPerCentimeter)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: min(20, rect.width * 0.34), weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.92)
        ]

        for mark in 0...units {
            let text = "\(mark)" as NSString
            let size = text.size(withAttributes: attrs)
            let x: CGFloat = 30
            let y = CGFloat(mark) * pointsPerCentimeter - (size.height / 2)
            text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        }
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
