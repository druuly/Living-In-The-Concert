import SwiftUI
import Charts

struct GSRGraphView: View {
    @ObservedObject var bleManager: BLEManager

    private let cardBg: Color = Color(.systemGray6)
    private let chartBg: Color = Color(.systemBackground)
    private let chartBorder: Color = Color(.systemGray4)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if bleManager.gsrHistory.isEmpty {
                    emptyState
                } else {
                    currentGSR
                    gsrWaveform
                    gsrStats
                }
            }
            .padding()
        }
        .navigationTitle("GSR")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No GSR Data")
                .font(.headline)
            Text("Connect to ESP32 to start recording skin conductance")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var currentGSR: some View {
        VStack(spacing: 6) {
            Text("\(bleManager.gsrValue)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
                .monospacedDigit()
            Text("GSR (ADC 0–4095)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
            Text(gsrLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cardBg)
        .cornerRadius(16)
    }

    private var gsrWaveform: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Skin Conductance Waveform", systemImage: "waveform.path")
                .font(.caption)
                .foregroundColor(.secondary)
            gsrChart
                .frame(height: 200)
                .padding(12)
                .background(chartBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(chartBorder, lineWidth: 0.5))
                .cornerRadius(12)
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(16)
    }

    private var gsrChart: some View {
        let history = bleManager.gsrHistory
        return Chart {
            ForEach(history.indices, id: \.self) { (i: Int) in
                LineMark(
                    x: .value("Time", history[i].0),
                    y: .value("GSR", history[i].1)
                )
                .foregroundStyle(Color.purple)
                .interpolationMethod(.catmullRom)
            }
            if let avg = gsrAverage {
                RuleMark(y: .value("Avg", avg))
                    .foregroundStyle(Color.blue.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: gsrYDomain)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))").font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.second())
            }
        }
    }

    private var gsrStats: some View {
        let values = bleManager.gsrHistory.map { $0.1 }
        let minVal = Int(values.min() ?? 0)
        let maxVal = Int(values.max() ?? 0)
        let avgVal = gsrAverage.map { Int($0) } ?? 0
        return HStack(spacing: 0) {
            statCell(label: "Min", value: "\(minVal)", color: .blue)
            Divider().frame(height: 40)
            statCell(label: "Avg", value: "\(avgVal)", color: .purple)
            Divider().frame(height: 40)
            statCell(label: "Max", value: "\(maxVal)", color: .red)
            Divider().frame(height: 40)
            statCell(label: "Samples", value: "\(bleManager.gsrHistory.count)", color: .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cardBg)
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private var gsrAverage: Double? {
        guard bleManager.gsrHistory.count > 1 else { return nil }
        let sum = bleManager.gsrHistory.map { $0.1 }.reduce(0, +)
        return sum / Double(bleManager.gsrHistory.count)
    }

    private var gsrYDomain: ClosedRange<Double> {
        let values = bleManager.gsrHistory.map { $0.1 }
        let lo = max(0, (values.min() ?? 0) - 50)
        let hi = min(4095, (values.max() ?? 4095) + 50)
        return lo...hi
    }

    // Rough qualitative label based on ADC range (calibrate to your module)
    private var gsrLabel: String {
        let v = bleManager.gsrValue
        switch v {
        case 0..<500:   return "Very low conductance"
        case 500..<1500: return "Low conductance"
        case 1500..<2500: return "Moderate conductance"
        case 2500..<3500: return "High conductance"
        default:         return "Very high conductance"
        }
    }

    private func statCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(1)
            Text(value)
                .font(.title3.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GSRGraphView(bleManager: BLEManager())
}
