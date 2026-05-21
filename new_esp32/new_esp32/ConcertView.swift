import SwiftUI

struct ConcertView: View {
    @ObservedObject var bleManager: BLEManager

    enum FlowState {
        case intro
        case baseline
        case recording(BaselineResult)
        case review(URL, [PeakMoment])
    }

    @State private var flow: FlowState = .intro

    var body: some View {
        switch flow {
        case .intro:
            introView
        case .baseline:
            BaselineView(bleManager: bleManager) { result in
                flow = .recording(result)
            }
        case .recording(let baseline):
            ConcertRecordingView(bleManager: bleManager, baseline: baseline) { url, peaks in
                flow = .review(url, peaks)
            }
        case .review(let url, let peaks):
            PeakReviewView(videoURL: url, peaks: peaks) {
                flow = .intro
            }
        }
    }

    private var introView: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.purple)

                VStack(spacing: 8) {
                    Text("Concert Mode")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Records video and biometric peaks\nduring live events.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Label("Calibrate your resting baseline (60 s)", systemImage: "1.circle.fill")
                    Label("Record video with the back camera", systemImage: "2.circle.fill")
                    Label("Peaks auto-stamped when HR + GSR both exceed baseline by 20%", systemImage: "3.circle.fill")
                    Label("Review peak moments and save the log after the show", systemImage: "4.circle.fill")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                if bleManager.state != .connected {
                    Label("Connect your sensor first", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.subheadline)
                }

                Button(action: { flow = .baseline }) {
                    Text("Begin Baseline Calibration")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(bleManager.state == .connected ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(bleManager.state != .connected)
            }
            .padding(.vertical, 36)
        }
    }
}
