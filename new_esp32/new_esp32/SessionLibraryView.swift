import SwiftUI
import AVFoundation
import AVKit
import UniformTypeIdentifiers

// MARK: - Transferable peaks export (no temp file needed)

struct PeaksExport: Transferable {
    let peaks: [PeakMoment]
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { export in
            try JSONEncoder().encode(export.peaks)
        }
        .suggestedFileName { export in export.filename }
    }
}

// MARK: - Library

struct SessionLibraryView: View {
    @ObservedObject var store: SessionStore
    @State private var selectedSession: ConcertSession?
    @Environment(\.editMode) private var editMode

    var body: some View {
        NavigationView {
            Group {
                if store.sessions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.sessions) { session in
                            Button(action: { selectedSession = session }) {
                                SessionRow(session: session)
                            }
                            .buttonStyle(.plain)
                            .contextMenu { contextMenu(for: session) }
                        }
                        .onDelete { store.delete(at: $0) }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !store.sessions.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(item: $selectedSession) { session in
                PeakReviewView(videoURL: session.videoURL, peaks: session.peaks) {
                    selectedSession = nil
                }
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for session: ConcertSession) -> some View {
        Button { selectedSession = session } label: {
            Label("Play", systemImage: "play.fill")
        }

        Divider()

        ShareLink(
            item: session.videoURL,
            preview: SharePreview(
                session.date.formatted(date: .abbreviated, time: .shortened),
                image: Image(systemName: "film")
            )
        ) {
            Label("Share Video", systemImage: "square.and.arrow.up")
        }

        let export = PeaksExport(
            peaks: session.peaks,
            filename: "peaks_\(Int(session.date.timeIntervalSince1970)).json"
        )
        ShareLink(
            item: export,
            preview: SharePreview("Peaks JSON", image: Image(systemName: "doc.text"))
        ) {
            Label("Export Peaks JSON", systemImage: "doc.badge.arrow.up")
        }

        Divider()

        Button(role: .destructive) {
            if let index = store.sessions.firstIndex(where: { $0.id == session.id }) {
                store.delete(at: IndexSet(integer: index))
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Saved Sessions")
                .font(.headline)
            Text("Concert recordings appear here automatically after each session.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

struct SessionRow: View {
    let session: ConcertSession
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            thumbnailView
            VStack(alignment: .leading, spacing: 5) {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Text(session.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 14) {
                    Label("\(session.peaks.count) peaks", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Label("\(Int(session.baseline.avgHR)) BPM rest", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 6)
        .task { thumbnail = await loadThumbnail(url: session.videoURL) }
    }

    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
            if let img = thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "film")
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 72, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadThumbnail(url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 144, height: 108)
        guard let cgImage = try? await gen.image(at: .zero).image else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
