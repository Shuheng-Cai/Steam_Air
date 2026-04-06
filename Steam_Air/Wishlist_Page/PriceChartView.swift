//
//  PriceChartView.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import UIKit

final class PriceChartView: UIView {

    var dataPoints: [PricePoint] = [] {
        didSet {
            tooltipLabel.isHidden = true
            setNeedsDisplay()
        }
    }

    private var tooltipIndex: Int = -1

    private let tooltipLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white
        l.backgroundColor = .systemBlue
        l.textAlignment = .center
        l.numberOfLines = 2
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        l.isHidden = true
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(tooltipLabel)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    private let inset = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8)

    override func draw(_ rect: CGRect) {
        guard dataPoints.count > 1 else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let drawRect = rect.inset(by: inset)
        let prices = dataPoints.map { $0.price }
        let minP = (prices.min() ?? 0) * 0.85
        let maxP = (prices.max() ?? 1) * 1.05
        let rangeP = maxP - minP > 0 ? maxP - minP : 1

        let xStep = drawRect.width / CGFloat(dataPoints.count - 1)

        func point(at index: Int) -> CGPoint {
            let x = drawRect.minX + CGFloat(index) * xStep
            let normalized = CGFloat((dataPoints[index].price - minP) / rangeP)
            let y = drawRect.maxY - normalized * drawRect.height
            return CGPoint(x: x, y: y)
        }

        // Fill area under line
        let fillPath = UIBezierPath()
        fillPath.move(to: CGPoint(x: drawRect.minX, y: drawRect.maxY))
        for i in 0..<dataPoints.count {
            fillPath.addLine(to: point(at: i))
        }
        fillPath.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))
        fillPath.close()
        UIColor.systemBlue.withAlphaComponent(0.12).setFill()
        fillPath.fill()

        // Draw line
        let linePath = UIBezierPath()
        for i in 0..<dataPoints.count {
            let pt = point(at: i)
            if i == 0 { linePath.move(to: pt) } else { linePath.addLine(to: pt) }
        }
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        linePath.stroke()

        // Tooltip vertical line
        if tooltipIndex >= 0 && tooltipIndex < dataPoints.count {
            let tx = point(at: tooltipIndex).x
            context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(1)
            context.setLineDash(phase: 0, lengths: [4, 4])
            context.move(to: CGPoint(x: tx, y: drawRect.minY))
            context.addLine(to: CGPoint(x: tx, y: drawRect.maxY))
            context.strokePath()

            // Dot at the data point
            context.setLineDash(phase: 0, lengths: [])
            let dotRect = CGRect(x: tx - 4, y: point(at: tooltipIndex).y - 4, width: 8, height: 8)
            context.setFillColor(UIColor.systemBlue.cgColor)
            context.fillEllipse(in: dotRect)
        }
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard dataPoints.count > 1 else { return }

        let location = recognizer.location(in: self)
        let drawRect = bounds.inset(by: inset)
        let xStep = drawRect.width / CGFloat(dataPoints.count - 1)
        let relativeX = location.x - drawRect.minX
        let index = max(0, min(dataPoints.count - 1, Int((relativeX / xStep).rounded())))

        tooltipIndex = index
        let point = dataPoints[index]

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        tooltipLabel.text = "\(formatter.string(from: point.date))\n$\(String(format: "%.2f", point.price))"
        tooltipLabel.isHidden = false
        tooltipLabel.sizeToFit()

        let labelW = tooltipLabel.frame.width + 16
        let labelH = tooltipLabel.frame.height + 8
        let tx = drawRect.minX + CGFloat(index) * xStep
        var labelX = tx - labelW / 2
        labelX = max(4, min(bounds.width - labelW - 4, labelX))
        tooltipLabel.frame = CGRect(x: labelX, y: 4, width: labelW, height: labelH)

        setNeedsDisplay()
    }
}
