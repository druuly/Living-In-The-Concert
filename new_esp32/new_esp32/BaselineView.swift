import SwiftUI

struct BaselineView: View {
    @ObservedObject var bleManager: BLEManager
    let onComplete: (BaselineResult) -> Void

    private let duration = 60

    @State private var secondsElapsed = 0
    @State private var hrSamples: [Double] = []
    @State private var gsrSamples: [Double] = []
    @State private var collectTimer: Timer?
    @State private var isCollecting = false

    var body: some View {
        VStack(spacing: 28) {
            Text("Baseline Calibration")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sit quietly for 60 seconds.\nWe'll record your resting heart rate and skin conductance.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: isCollecting ? CGFloat(secondsElapsed) / CGFloat(duration) : 0)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: secondsElapsed)

                VStack(spacing: 4) {
                    if isCollecting {
                        Text("\(duration - secondsElapsed)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                        Text("seconds left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ready")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            }
            .frame(width: 200, height: 200)

            if isCollecting {
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("HR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(bleManager.bpm) BPM")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.semibold)
                    }
                    VStack(spacing: 4) {
                        Text("GSR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(bleManager.gsrValue)")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            if !isCollecting {
                Button(action: startCollecting) {
                    Text("Start Calibration")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onDisappear { collectTimer?.invalidate() }
    }

    private func startCollecting() {
        hrSamples = []
        gsrSamples = []
        secondsElapsed = 0
        isCollecting = true

        collectTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if bleManager.bpm > 20 {
                hrSamples.append(Double(bleManager.bpm))
            }
            gsrSamples.append(Double(bleManager.gsrValue))
            secondsElapsed += 1

            if secondsElapsed >= duration {
                collectTimer?.invalidate()
                finish()
            }
        }
    }

    private func finish() {
        let avgHR = hrSamples.isEmpty ? 70.0 : hrSamples.reduce(0, +) / Double(hrSamples.count)
        let avgGSR = gsrSamples.isEmpty ? 2048.0 : gsrSamples.reduce(0, +) / Double(gsrSamples.count)
        onComplete(BaselineResult(avgHR: avgHR, avgGSR: avgGSR))
    }
}
