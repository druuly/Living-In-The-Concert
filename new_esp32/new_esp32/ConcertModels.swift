import Foundation

struct BaselineResult {
    let avgHR: Double
    let avgGSR: Double
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
