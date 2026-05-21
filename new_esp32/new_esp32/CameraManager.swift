import AVFoundation
import Combine

class CameraManager: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var recordingStartDate: Date?
    private var recordingCompletion: ((URL?) -> Void)?

    @Published var isReady = false
    @Published var isRecording = false

    var currentVideoTimestamp: Double {
        guard let start = recordingStartDate else { return 0 }
        return Date().timeIntervalSince(start)
    }

    func setup() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let cameraInput = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(cameraInput) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(cameraInput)

            if let mic = AVCaptureDevice.default(for: .audio),
               let micInput = try? AVCaptureDeviceInput(device: mic),
               self.session.canAddInput(micInput) {
                self.session.addInput(micInput)
            }

            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async { self.isReady = true }
        }
    }

    func startRecording() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        recordingStartDate = Date()
        movieOutput.startRecording(to: url, recordingDelegate: self)
        DispatchQueue.main.async { self.isRecording = true }
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        recordingCompletion = completion
        movieOutput.stopRecording()
        DispatchQueue.main.async { self.isRecording = false }
    }

    func teardown() {
        if session.isRunning { session.stopRunning() }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.recordingCompletion?(error == nil ? outputFileURL : nil)
            self.recordingCompletion = nil
        }
    }
}
