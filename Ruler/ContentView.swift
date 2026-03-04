//
//  ContentView.swift
//  Ruler
//
//  UIKit implementation for iOS 13+ support.
//

import UIKit

protocol ResettableModeController: UIViewController {
    func handleResetAction()
}

final class RulerViewController: UIViewController {
    private let containerView = UIView()
    private let resetButton = UIButton(type: .system)
    private var resetButtonCenterYConstraint: NSLayoutConstraint?

    private let rulerModeViewController = RulerModeViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupContainerView()
        setupResetButton()
        showRulerModeIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeHeight = view.safeAreaLayoutGuide.layoutFrame.height
        resetButtonCenterYConstraint?.constant = safeHeight * 0.75
    }

    private func setupContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupResetButton() {
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        resetButton.backgroundColor = UIColor(white: 0.18, alpha: 0.95)
        resetButton.layer.cornerRadius = 26
        resetButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 30, bottom: 14, right: 30)
        resetButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        resetButton.setContentHuggingPriority(.required, for: .horizontal)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        view.addSubview(resetButton)

        let guide = view.safeAreaLayoutGuide
        let centerYConstraint = resetButton.centerYAnchor.constraint(equalTo: guide.topAnchor)
        resetButtonCenterYConstraint = centerYConstraint
        NSLayoutConstraint.activate([
            resetButton.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            centerYConstraint,
            resetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            resetButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160)
        ])
    }

    @objc private func resetTapped() {
        rulerModeViewController.handleResetAction()
    }

    private func showRulerModeIfNeeded() {
        guard rulerModeViewController.parent == nil else { return }

        addChild(rulerModeViewController)
        rulerModeViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(rulerModeViewController.view)
        NSLayoutConstraint.activate([
            rulerModeViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            rulerModeViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            rulerModeViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rulerModeViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        rulerModeViewController.didMove(toParent: self)
    }
}

final class RulerModeViewController: UIViewController, ResettableModeController {
    private struct AppliedScale: Equatable {
        let pointsPerCentimeter: CGFloat
    }

    private let rulerView = RulerCanvasView()
    private var panStartOffsetY: CGFloat = 0
    private var appliedScale: AppliedScale?

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

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
        applyCurrentScale()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyCurrentScale()
        rulerView.contentOffsetY = rulerView.clampedOffsetY(rulerView.contentOffsetY)
    }

    func handleResetAction() {
        rulerView.contentOffsetY = 0
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panStartOffsetY = rulerView.contentOffsetY
        case .changed, .ended:
            let deltaY = gesture.translation(in: view).y
            let nextOffset = panStartOffsetY - deltaY
            rulerView.contentOffsetY = rulerView.clampedOffsetY(nextOffset)
        default:
            break
        }
    }

    private func applyCurrentScale() {
        let model = DeviceScaleModel.resolve(
            identifier: DeviceIdentifier.current,
            category: DeviceCategory.from(idiom: UIDevice.current.userInterfaceIdiom),
            pixelsPerPoint: max(UIScreen.main.nativeScale, UIScreen.main.scale),
            simulatorName: DeviceIdentifier.simulatorName
        )

        let nextScale = AppliedScale(pointsPerCentimeter: model.pointsPerCentimeter)
        guard nextScale != appliedScale else { return }

        appliedScale = nextScale
        rulerView.pointsPerCentimeter = model.pointsPerCentimeter
    }
}

private final class RulerCanvasView: UIView {
    private enum PanelAlignment {
        case left
        case right
    }

    var pointsPerCentimeter: CGFloat = 72 {
        didSet {
            if abs(pointsPerCentimeter - oldValue) > 0.0001 {
                setNeedsDisplay()
            }
        }
    }

    var contentOffsetY: CGFloat = 0 {
        didSet {
            if abs(contentOffsetY - oldValue) > 0.0001 {
                setNeedsDisplay()
            }
        }
    }

    private let preferredPanelWidth: CGFloat = 68
    private let panelSpacing: CGFloat = 16
    private let sideInset: CGFloat = 10
    private let topBottomInset: CGFloat = 8
    private let maxCentimeters: CGFloat = 250

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let clamped = clampedOffsetY(contentOffsetY)
        if abs(clamped - contentOffsetY) > 0.0001 {
            contentOffsetY = clamped
        }
    }

    func clampedOffsetY(_ proposedOffset: CGFloat) -> CGFloat {
        let upperBound = maximumOffsetY
        return min(max(proposedOffset, 0), upperBound)
    }

    private var maximumOffsetY: CGFloat {
        guard pointsPerCentimeter > 0 else { return 0 }
        let contentFrame = scaleContentFrame(in: bounds)
        let visibleHeight = max(contentFrame.height, 0)
        let totalHeight = maxCentimeters * pointsPerCentimeter
        return max(totalHeight - visibleHeight, 0)
    }

    private func configureView() {
        backgroundColor = .black
        isOpaque = true
        contentMode = .redraw
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), pointsPerCentimeter > 0 else { return }

        UIColor.black.setFill()
        ctx.fill(rect)

        let contentFrame = scaleContentFrame(in: rect)
        guard contentFrame.width > 120, contentFrame.height > 100 else { return }

        let panelWidth = min(preferredPanelWidth, max((contentFrame.width - panelSpacing) * 0.5, 48))
        let leftPanel = CGRect(x: contentFrame.minX, y: contentFrame.minY, width: panelWidth, height: contentFrame.height)
        let rightPanel = CGRect(x: contentFrame.maxX - panelWidth, y: contentFrame.minY, width: panelWidth, height: contentFrame.height)

        drawScalePanelBackground(in: ctx, panel: leftPanel)
        drawScalePanelBackground(in: ctx, panel: rightPanel)

        drawVerticalScale(in: ctx, panel: leftPanel, unit: .centimeter, alignment: .left)
        drawVerticalScale(in: ctx, panel: rightPanel, unit: .inch, alignment: .right)
    }

    private func scaleContentFrame(in rect: CGRect) -> CGRect {
        let insets = safeAreaInsets
        return rect.inset(by: UIEdgeInsets(
            top: insets.top + topBottomInset,
            left: insets.left + sideInset,
            bottom: insets.bottom + topBottomInset,
            right: insets.right + sideInset
        ))
    }

    private func drawScalePanelBackground(in ctx: CGContext, panel: CGRect) {
        UIColor(white: 0.10, alpha: 1).setFill()
        ctx.fill(panel)

        UIColor(white: 0.24, alpha: 1).setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(panel)
    }

    private func drawVerticalScale(in ctx: CGContext, panel: CGRect, unit: RulerUnit, alignment: PanelAlignment) {
        let pointsPerUnit = RulerScaleMath.pointsPerUnit(pointsPerCentimeter: pointsPerCentimeter, unit: unit)
        let subdivisions = unit.subdivisions
        let minorStep = pointsPerUnit / CGFloat(subdivisions)
        guard minorStep > 0 else { return }

        UIColor.white.withAlphaComponent(0.95).setStroke()
        ctx.setLineWidth(1)

        guard let tickRange = RulerScaleMath.minorTickRange(
            offset: contentOffsetY,
            viewportStart: 0,
            viewportEnd: panel.height,
            minorStep: minorStep
        ) else { return }

        let halfSubdivision = max(subdivisions / 2, 1)
        for tick in tickRange {
            if tick < 0 { continue }
            let y = panel.minY + CGFloat(tick) * minorStep - contentOffsetY
            guard y >= panel.minY - minorStep, y <= panel.maxY + minorStep else { continue }

            let tickLength: CGFloat
            if tick % subdivisions == 0 {
                tickLength = 28
            } else if tick % halfSubdivision == 0 {
                tickLength = 20
            } else {
                tickLength = 12
            }

            switch alignment {
            case .left:
                ctx.move(to: CGPoint(x: panel.minX + 1, y: y))
                ctx.addLine(to: CGPoint(x: panel.minX + tickLength, y: y))
            case .right:
                ctx.move(to: CGPoint(x: panel.maxX - 1, y: y))
                ctx.addLine(to: CGPoint(x: panel.maxX - tickLength, y: y))
            }
        }
        ctx.strokePath()

        guard let majorRange = RulerScaleMath.majorTickRange(
            offset: contentOffsetY,
            viewportStart: 0,
            viewportEnd: panel.height,
            pointsPerUnit: pointsPerUnit
        ) else { return }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.92)
        ]

        for major in majorRange {
            if major < 0 { continue }
            let y = panel.minY + CGFloat(major) * pointsPerUnit - contentOffsetY
            guard y >= panel.minY - pointsPerUnit, y <= panel.maxY + pointsPerUnit else { continue }

            let text = "\(major)" as NSString
            let size = text.size(withAttributes: attrs)
            let x: CGFloat
            switch alignment {
            case .left:
                x = panel.maxX - size.width - 8
            case .right:
                x = panel.minX + 8
            }
            text.draw(at: CGPoint(x: x, y: y - size.height / 2), withAttributes: attrs)
        }

        let unitText = unit.title.uppercased() as NSString
        let unitAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.systemGreen.withAlphaComponent(0.95)
        ]
        let unitSize = unitText.size(withAttributes: unitAttrs)
        let unitX: CGFloat
        switch alignment {
        case .left:
            unitX = panel.maxX - unitSize.width - 8
        case .right:
            unitX = panel.minX + 8
        }
        unitText.draw(at: CGPoint(x: unitX, y: panel.minY + 6), withAttributes: unitAttrs)
    }
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

    static var simulatorName: String? {
#if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"]
#else
        return nil
#endif
    }
}

private extension DeviceCategory {
    static func from(idiom: UIUserInterfaceIdiom) -> DeviceCategory {
        switch idiom {
        case .phone:
            return .phone
        case .pad:
            return .pad
        case .tv:
            return .tv
        case .carPlay:
            return .unknown
        default:
            if #available(iOS 14.0, *), idiom == .mac {
                return .mac
            }
            return .unknown
        }
    }
}
