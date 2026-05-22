import Foundation
import Combine
import SwiftUI

class SessionStore: ObservableObject {
    @Published var sessions: [ConcertSession] = []

    private let storageURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("concert_sessions.json")

    init() { load() }

    func save(tempVideoURL: URL, peaks: [PeakMoment], baseline: BaselineResult) {
        let filename = "concert_\(Int(Date().timeIntervalSince1970)).mov"
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        guard (try? FileManager.default.copyItem(at: tempVideoURL, to: dest)) != nil else { return }
        let session = ConcertSession(date: Date(), videoFilename: filename, peaks: peaks, baseline: baseline)
        sessions.insert(session, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            try? FileManager.default.removeItem(at: sessions[index].videoURL)
        }
        sessions.remove(atOffsets: offsets)
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([ConcertSession].self, from: data) else { return }
        sessions = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: storageURL)
    }
}
