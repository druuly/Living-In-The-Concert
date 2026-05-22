import SwiftUI
import AVKit

struct PeakReviewView: View {
    let videoURL: URL
    let peaks: [PeakMoment]
    let onDone: () -> Void

    @State private var player: AVPlayer
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false

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
            }
            .navigationTitle("Concert Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { onDone() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: shareVideo) {
                            Label("Share Video", systemImage: "film")
                        }
                        Button(action: sharePeaksJSON) {
                            Label("Export Peaks JSON", systemImage: "doc.badge.arrow.up")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onAppear { player.play() }
            .sheet(isPresented: $showingShareSheet) {
                ActivityView(items: shareItems)
            }
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

    private func shareVideo() {
        shareItems = [videoURL]
        showingShareSheet = true
    }

    private func sharePeaksJSON() {
        guard let data = try? JSONEncoder().encode(peaks) else { return }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("peaks_\(Int(Date().timeIntervalSince1970)).json")
        try? data.write(to: tmp)
        shareItems = [tmp]
        showingShareSheet = true
    }
}

// UIActivityViewController wrapper
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
