//
//  PriceChartView.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

internal import UIKit

final class PriceChartView: UIView {

    var dataPoints: [PricePoint] = [] {
        didSet {
            tooltipIndex = -1
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

    // MARK: - Layout constants

    /// Left gutter width for Y-axis price labels
    private let yAxisWidth: CGFloat  = 46
    /// Bottom gutter height for X-axis date labels
    private let xAxisHeight: CGFloat = 20
    /// Internal padding around the plot area
    private let plotPad = UIEdgeInsets(top: 20, left: 6, bottom: 4, right: 6)

    private func plotRect(in bounds: CGRect) -> CGRect {
        CGRect(
            x: yAxisWidth + plotPad.left,
            y: plotPad.top,
            width: bounds.width  - yAxisWidth  - plotPad.left - plotPad.right,
            height: bounds.height - xAxisHeight - plotPad.top  - plotPad.bottom
        )
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard dataPoints.count > 1 else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let plot = plotRect(in: rect)
        let prices = dataPoints.map { $0.price }
        let minP   = (prices.min() ?? 0) * 0.85
        let maxP   = (prices.max() ?? 1) * 1.05
        let rangeP = maxP - minP > 0 ? maxP - minP : 1
        let xStep  = plot.width / CGFloat(dataPoints.count - 1)

        func chartPoint(at index: Int) -> CGPoint {
            let x = plot.minX + CGFloat(index) * xStep
            let normalized = CGFloat((dataPoints[index].price - minP) / rangeP)
            let y = plot.maxY - normalized * plot.height
            return CGPoint(x: x, y: y)
        }

        // MARK: Y-axis gridlines + labels (3 levels)
        let yLevels: [Double] = [minP, (minP + maxP) / 2, maxP]
        let axisAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryLabel,
        ]
        for price in yLevels {
            let normalized = CGFloat((price - minP) / rangeP)
            let y = plot.maxY - normalized * plot.height

            // Dashed gridline
            context.setStrokeColor(UIColor.separator.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(0.5)
            context.setLineDash(phase: 0, lengths: [3, 3])
            context.move(to: CGPoint(x: plot.minX, y: y))
            context.addLine(to: CGPoint(x: plot.maxX, y: y))
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])

            // Price label right-aligned in the Y-axis gutter
            let str  = String(format: "$%.0f", price) as NSString
            let size = str.size(withAttributes: axisAttrs)
            str.draw(in: CGRect(x: yAxisWidth - size.width - 4,
                                y: y - size.height / 2,
                                width: size.width, height: size.height),
                     withAttributes: axisAttrs)
        }

        // MARK: X-axis labels (first, middle, last)
        let xFmt = DateFormatter()
        xFmt.dateFormat = "MMM yy"
        let xIndices = [0, dataPoints.count / 2, dataPoints.count - 1]
        for idx in xIndices {
            let x   = plot.minX + CGFloat(idx) * xStep
            let str = xFmt.string(from: dataPoints[idx].date) as NSString
            let sz  = str.size(withAttributes: axisAttrs)
            var lx  = x - sz.width / 2
            lx = max(yAxisWidth, min(rect.width - sz.width, lx))
            str.draw(in: CGRect(x: lx, y: plot.maxY + plotPad.bottom + 2,
                                width: sz.width, height: sz.height),
                     withAttributes: axisAttrs)
        }

        // MARK: Fill under line
        let fillPath = UIBezierPath()
        fillPath.move(to: CGPoint(x: plot.minX, y: plot.maxY))
        for i in 0..<dataPoints.count { fillPath.addLine(to: chartPoint(at: i)) }
        fillPath.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
        fillPath.close()
        UIColor.systemBlue.withAlphaComponent(0.12).setFill()
        fillPath.fill()

        // MARK: Line
        let linePath = UIBezierPath()
        for i in 0..<dataPoints.count {
            let pt = chartPoint(at: i)
            if i == 0 { linePath.move(to: pt) } else { linePath.addLine(to: pt) }
        }
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        linePath.stroke()

        // MARK: Min / Max markers
        if let maxPrice = prices.max(), let minPrice = prices.min(),
           let maxIdx   = prices.firstIndex(of: maxPrice),
           let minIdx   = prices.firstIndex(of: minPrice),
           maxIdx != minIdx {
            drawPriceMarker(
                context: context,
                at: chartPoint(at: maxIdx),
                price: maxPrice,
                isHigh: true,
                plot: plot
            )
            drawPriceMarker(
                context: context,
                at: chartPoint(at: minIdx),
                price: minPrice,
                isHigh: false,
                plot: plot
            )
        }

        // MARK: Tooltip crosshair + dot
        if tooltipIndex >= 0 && tooltipIndex < dataPoints.count {
            let tx = chartPoint(at: tooltipIndex).x
            context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(1)
            context.setLineDash(phase: 0, lengths: [4, 4])
            context.move(to: CGPoint(x: tx, y: plot.minY))
            context.addLine(to: CGPoint(x: tx, y: plot.maxY))
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])

            let dot = chartPoint(at: tooltipIndex)
            context.setFillColor(UIColor.systemBlue.cgColor)
            context.fillEllipse(in: CGRect(x: dot.x - 4, y: dot.y - 4, width: 8, height: 8))
        }
    }

    // MARK: - Min/Max marker helper

    private func drawPriceMarker(context: CGContext,
                                  at point: CGPoint,
                                  price: Double,
                                  isHigh: Bool,
                                  plot: CGRect) {
        let color: UIColor = isHigh ? .systemRed : .systemGreen

        // Dot with white border
        let r: CGFloat = 5
        let dotRect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: dotRect)
        context.setStrokeColor(UIColor.systemBackground.cgColor)
        context.setLineWidth(1.5)
        context.strokeEllipse(in: dotRect)

        // Price label — above for high, below for low
        let labelStr = String(format: "$%.2f", price) as NSString
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: color,
        ]
        let labelSize = labelStr.size(withAttributes: labelAttrs)
        let gap: CGFloat = 4
        let labelY: CGFloat = isHigh
            ? point.y - r - gap - labelSize.height
            : point.y + r + gap

        // Clamp X so label stays inside the plot area
        var labelX = point.x - labelSize.width / 2
        labelX = max(yAxisWidth, min(plot.maxX - labelSize.width, labelX))

        // Ensure label stays inside vertical bounds
        let clampedY = max(0, min(plot.maxY - labelSize.height, labelY))

        labelStr.draw(in: CGRect(x: labelX, y: clampedY,
                                 width: labelSize.width, height: labelSize.height),
                      withAttributes: labelAttrs)
    }

    // MARK: - Tap to show tooltip

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard dataPoints.count > 1 else { return }

        let location = recognizer.location(in: self)
        let plot  = plotRect(in: bounds)
        let xStep = plot.width / CGFloat(dataPoints.count - 1)
        let index = max(0, min(dataPoints.count - 1,
                               Int(((location.x - plot.minX) / xStep).rounded())))

        tooltipIndex = index
        let dp = dataPoints[index]

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        tooltipLabel.text = "\(formatter.string(from: dp.date))\n$\(String(format: "%.2f", dp.price))"
        tooltipLabel.isHidden = false
        tooltipLabel.sizeToFit()

        let labelW = tooltipLabel.frame.width + 16
        let labelH = tooltipLabel.frame.height + 8
        let tx = plot.minX + CGFloat(index) * xStep
        var labelX = tx - labelW / 2
        labelX = max(yAxisWidth, min(bounds.width - labelW - 4, labelX))
        tooltipLabel.frame = CGRect(x: labelX, y: 4, width: labelW, height: labelH)

        setNeedsDisplay()
    }
}
