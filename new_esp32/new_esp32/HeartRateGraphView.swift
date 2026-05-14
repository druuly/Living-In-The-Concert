import SwiftUI
import Charts

struct HeartRateGraphView: View {
    @ObservedObject var bleManager: BLEManager

    // Typed constants give the compiler unambiguous context for Color(.systemGrayX)
    private let cardBg: Color = Color(.systemGray6)
    private let chartBg: Color = Color(.systemBackground)
    private let chartBorder: Color = Color(.systemGray4)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if bleManager.ppgHistory.isEmpty && bleManager.bpmHistory.isEmpty {
                    emptyState
                } else {
                    currentBPM
                    if !bleManager.ppgHistory.isEmpty {
                        ppgWaveform
                    } else if !bleManager.bpmHistory.isEmpty {
                        bpmTrendGraph
                    }
                    stats
                }
            }
            .padding()
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Heart Rate Data")
                .font(.headline)
            Text("Connect to ESP32 and place finger on sensor to start recording")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var currentBPM: some View {
        VStack(spacing: 6) {
            Text("\(bleManager.bpm)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.red)
                .monospacedDigit()
            Text("BPM")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
            HStack(spacing: 6) {
                Circle()
                    .fill(bleManager.fingerOnSensor ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(bleManager.fingerOnSensor ? "Finger detected" : "Place finger on sensor")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cardBg)
        .cornerRadius(16)
    }

    private var ppgWaveform: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pulse Waveform", systemImage: "waveform.path.ecg")
                .font(.caption)
                .foregroundColor(.secondary)
            ppgChart
                .frame(height: 180)
                .padding(12)
                .background(chartBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(chartBorder, lineWidth: 0.5))
                .cornerRadius(12)
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(16)
    }

    private var ppgChart: some View {
        let history = bleManager.ppgHistory
        return Chart {
            ForEach(history.indices, id: \.self) { (i: Int) in
                LineMark(
                    x: .value("Time", history[i].0),
                    y: .value("Signal", history[i].1)
                )
                .foregroundStyle(Color.red)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: ppgYDomain)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))")
                            .font(.caption2)
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

    private var bpmTrendGraph: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("BPM Trend", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption)
                .foregroundColor(.secondary)
            bpmChart
                .frame(height: 180)
                .padding(12)
                .background(chartBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(chartBorder, lineWidth: 0.5))
                .cornerRadius(12)
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(16)
    }

    private var bpmChart: some View {
        let history = bleManager.bpmHistory
        let avg = bpmAverage
        return Chart {
            ForEach(history.indices, id: \.self) { (i: Int) in
                LineMark(
                    x: .value("Time", history[i].0),
                    y: .value("BPM", history[i].1)
                )
                .foregroundStyle(Color.red.gradient)
                .interpolationMethod(.catmullRom)
            }
            if let avg {
                RuleMark(y: .value("Avg", avg))
                    .foregroundStyle(Color.blue.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: bpmYDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.minute().second())
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 10)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)").font(.caption2)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var ppgYDomain: ClosedRange<Double> {
        let bpm = Double(bleManager.bpm > 20 ? bleManager.bpm : 75)
        return (bpm - 22)...(bpm + 22)
    }

    private var bpmAverage: Double? {
        guard bleManager.bpmHistory.count > 1 else { return nil }
        let sum = bleManager.bpmHistory.map { $0.1 }.reduce(0, +)
        return Double(sum) / Double(bleManager.bpmHistory.count)
    }

    private var bpmYDomain: ClosedRange<Int> {
        let values = bleManager.bpmHistory.map { $0.1 }
        let lo = max(40, (values.min() ?? 60) - 10)
        let hi = min(200, (values.max() ?? 100) + 10)
        return lo...hi
    }

    private var stats: some View {
        HStack(spacing: 0) {
            statCell(label: "Min", value: "\(bleManager.bpmHistory.map { $0.1 }.min() ?? 0)", color: .blue)
            Divider().frame(height: 40)
            statCell(label: "Avg", value: "\(bleManager.avgBpm)", color: .green)
            Divider().frame(height: 40)
            statCell(label: "Max", value: "\(bleManager.bpmHistory.map { $0.1 }.max() ?? 0)", color: .red)
            Divider().frame(height: 40)
            statCell(label: "Samples", value: "\(bleManager.ppgHistory.count)", color: .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cardBg)
        .cornerRadius(16)
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
    HeartRateGraphView(bleManager: BLEManager())
}
