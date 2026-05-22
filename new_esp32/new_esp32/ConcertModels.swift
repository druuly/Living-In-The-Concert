import Foundation

struct BaselineResult: Codable {
    let avgHR: Double
    let avgGSR: Double
    let savedAt: Date

    init(avgHR: Double, avgGSR: Double) {
        self.avgHR = avgHR
        self.avgGSR = avgGSR
        self.savedAt = Date()
    }

    static func load() -> BaselineResult? {
        guard let data = UserDefaults.standard.data(forKey: "savedBaseline"),
              let result = try? JSONDecoder().decode(BaselineResult.self, from: data) else { return nil }
        return result
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: "savedBaseline")
    }
}

struct PeakMoment: Codable, Identifiable {
    let id: UUID
    let videoTimestamp: Double
    let wallClock: Date
    let hr: Int
    let gsr: Int

    init(videoTimestamp: Double, wallClock: Date, hr: Int, gsr: Int) {
        self.id = UUID()
        self.videoTimestamp = videoTimestamp
        self.wallClock = wallClock
        self.hr = hr
        self.gsr = gsr
    }
}

struct ConcertSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let videoFilename: String
    let peaks: [PeakMoment]
    let baseline: BaselineResult

    init(date: Date, videoFilename: String, peaks: [PeakMoment], baseline: BaselineResult) {
        self.id = UUID()
        self.date = date
        self.videoFilename = videoFilename
        self.peaks = peaks
        self.baseline = baseline
    }

    var videoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(videoFilename)
    }
}
