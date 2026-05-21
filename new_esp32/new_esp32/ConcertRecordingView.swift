import SwiftUI
import AVFoundation

struct ConcertRecordingView: View {
    @ObservedObject var bleManager: BLEManager
    let baseline: BaselineResult
    let onFinish: (URL, [PeakMoment]) -> Void

    @StateObject private var cameraManager = CameraManager()
    @State private var peaks: [PeakMoment] = []
    @State private var lastPeakTime: Date = .distantPast
    @State private var showPeakFlash = false
    @State private var isStarted = false

    private let excitementThreshold = 1.20
    private let peakCooldown: TimeInterval = 5.0

    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()

            if showPeakFlash {
                Color.yellow.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack {
                topHUD
                Spacer()
                bottomControls
            }
        }
        .onAppear { cameraManager.setup() }
        .onDisappear { cameraManager.teardown() }
        .onChange(of: bleManager.bpm) { checkForPeak() }
        .onChange(of: bleManager.gsrValue) { checkForPeak() }
    }

    private var topHUD: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Label("\(bleManager.bpm) BPM", systemImage: "heart.fill")
                    .foregroundColor(isExcitedHR ? .red : .white)
                Label("GSR \(bleManager.gsrValue)", systemImage: "waveform")
                    .foregroundColor(isExcitedGSR ? .yellow : .white)
            }
            .font(.headline)
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(10)

            Spacer()

            VStack(spacing: 2) {
                Text("\(peaks.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("peaks")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
        .padding()
    }

    private var bottomControls: some View {
        HStack(spacing: 20) {
            if !isStarted {
                Button(action: startRecording) {
                    Label("Record", systemImage: "record.circle")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
            } else {
                Button(action: stopRecording) {
                    Label("Stop", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(30)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text("REC")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
        .padding(.bottom, 44)
    }

    private var isExcitedHR: Bool {
        baseline.avgHR > 0 && Double(bleManager.bpm) > baseline.avgHR * excitementThreshold
    }

    private var isExcitedGSR: Bool {
        baseline.avgGSR > 0 && Double(bleManager.gsrValue) > baseline.avgGSR * excitementThreshold
    }

    private func checkForPeak() {
        guard isStarted,
              isExcitedHR,
              isExcitedGSR,
              Date().timeIntervalSince(lastPeakTime) >= peakCooldown else { return }

        let peak = PeakMoment(
            videoTimestamp: cameraManager.currentVideoTimestamp,
            wallClock: Date(),
            hr: bleManager.bpm,
            gsr: bleManager.gsrValue
        )
        peaks.append(peak)
        lastPeakTime = Date()

        withAnimation(.easeOut(duration: 0.15)) { showPeakFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { showPeakFlash = false }
        }
    }

    private func startRecording() {
        cameraManager.startRecording()
        isStarted = true
    }

    private func stopRecording() {
        cameraManager.stopRecording { url in
            guard let url else { return }
            onFinish(url, peaks)
        }
    }
}

// MARK: - Camera preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView { PreviewView(session: session) }
    func updateUIView(_ uiView: PreviewView, context: Context) {}

    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }

        required init?(coder: NSCoder) { fatalError() }
    }
}
