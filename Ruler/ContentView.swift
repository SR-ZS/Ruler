//
//  ContentView.swift
//  Ruler
//
//  Created by zhangshuai on 2/26/26.
//

import SwiftUI

struct ContentView: View {
    private let rulerThickness: CGFloat = 56
    private let topGap: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom
            let horizontalUnits = max(6, Int((proxy.size.width - rulerThickness - 16) / 45))
            let verticalUnits = max(12, Int((proxy.size.height - safeTop - safeBottom - 20) / 48))

            ZStack(alignment: .topLeading) {
                Color.black
                    .ignoresSafeArea()

                HorizontalRulerView(units: horizontalUnits, startValue: 1)
                    .frame(height: rulerThickness)
                    .padding(.top, safeTop + topGap)
                    .padding(.leading, rulerThickness - 2)
                    .padding(.trailing, 14)

                VerticalRulerView(units: verticalUnits, startValue: 1)
                    .frame(width: rulerThickness)
                    .padding(.top, safeTop + topGap)
                    .padding(.bottom, safeBottom + 10)

                Text(currentIPhoneName)
                    .font(.system(size: 38, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.gray.opacity(0.45))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private var currentIPhoneName: String {
#if targetEnvironment(simulator)
        ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "iPhone"
#else
        UIDevice.current.model
#endif
    }
}

private struct HorizontalRulerView: View {
    let units: Int
    let startValue: Int

    private let majorTickLength: CGFloat = 28
    private let mediumTickLength: CGFloat = 20
    private let minorTickLength: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let unitSpacing = width / CGFloat(max(units, 1))
            let minorSpacing = unitSpacing / 10
            let tickCount = Int(width / minorSpacing)
            let labelFontSize = min(20, proxy.size.height * 0.36)

            ZStack(alignment: .topLeading) {
                Path { path in
                    for tick in 0...tickCount {
                        let x = CGFloat(tick) * minorSpacing
                        let tickLength: CGFloat

                        if tick.isMultiple(of: 10) {
                            tickLength = majorTickLength
                        } else if tick.isMultiple(of: 5) {
                            tickLength = mediumTickLength
                        } else {
                            tickLength = minorTickLength
                        }

                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: tickLength))
                    }
                }
                .stroke(Color.white.opacity(0.95), lineWidth: 1)

                ForEach(1...units, id: \.self) { mark in
                    Text("\(startValue + mark - 1)")
                        .font(.system(size: labelFontSize, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .position(
                            x: CGFloat(mark) * unitSpacing,
                            y: majorTickLength + labelFontSize * 0.78
                        )
                }
            }
        }
    }
}

private struct VerticalRulerView: View {
    let units: Int
    let startValue: Int

    private let majorTickLength: CGFloat = 28
    private let mediumTickLength: CGFloat = 20
    private let minorTickLength: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let unitSpacing = height / CGFloat(max(units, 1))
            let minorSpacing = unitSpacing / 10
            let tickCount = Int(height / minorSpacing)
            let labelFontSize = min(34, proxy.size.width * 0.34)

            ZStack(alignment: .topLeading) {
                Path { path in
                    for tick in 0...tickCount {
                        let y = CGFloat(tick) * minorSpacing
                        let tickLength: CGFloat

                        if tick.isMultiple(of: 10) {
                            tickLength = majorTickLength
                        } else if tick.isMultiple(of: 5) {
                            tickLength = mediumTickLength
                        } else {
                            tickLength = minorTickLength
                        }

                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: tickLength, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.95), lineWidth: 1)

                ForEach(1...units, id: \.self) { mark in
                    Text("\(startValue + mark)")
                        .font(.system(size: labelFontSize, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .position(
                            x: majorTickLength + labelFontSize * 0.72,
                            y: CGFloat(mark) * unitSpacing
                        )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
