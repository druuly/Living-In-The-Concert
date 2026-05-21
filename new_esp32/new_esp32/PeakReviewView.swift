import SwiftUI
import AVKit

struct PeakReviewView: View {
    let videoURL: URL
    let peaks: [PeakMoment]
    let onDone: () -> Void

    @State private var player: AVPlayer
    @State private var savedConfirmation = false

    init(videoURL: URL, peaks: [PeakMoment], onDone: @escaping () -> Void) {
        self.videoURL = videoURL
        self.peaks = peaks
        self.onDone = onDone
        _player = State(initialValue: AVPlayer(url: videoURL))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VideoPlayer(player: player)
                    .frame(height: 280)

                List {
                    Section("Peak Moments (\(peaks.count))") {
                        if peaks.isEmpty {
                            Text("No peaks detected during this session.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(peaks) { peak in
                                Button(action: { seekAndPlay(to: peak.videoTimestamp) }) {
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                            .foregroundColor(.yellow)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(formatVideoTime(peak.videoTimestamp))
                                                .font(.headline)
                                            Text("HR \(peak.hr) BPM  ·  GSR \(peak.gsr)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if savedConfirmation {
                    Label("Peaks saved to Files", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Concert Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { onDone() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: savePeaksJSON) {
                        Label("Save Log", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .onAppear { player.play() }
        }
    }

    private func seekAndPlay(to seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        player.play()
    }

    private func formatVideoTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func savePeaksJSON() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "peaks_\(Int(Date().timeIntervalSince1970)).json"
        let url = docs.appendingPathComponent(filename)
        guard let data = try? JSONEncoder().encode(peaks) else { return }
        try? data.write(to: url)
        savedConfirmation = true
    }
}
