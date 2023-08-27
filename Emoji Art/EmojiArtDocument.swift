//
//  EmojiArtDocument.swift
//  Emoji Art
//
//  Created by JackKong on 2023/8/24.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let emojiart = UTType(exportedAs: "com.jackkong.emojiart")
}

class EmojiArtDocument: ReferenceFileDocument {
    func snapshot(contentType: UTType) throws -> Data {
        try emojisArt.json()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    static var readableContentTypes: [UTType] { [.emojiart] }
    
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojisArt = try .init(json: data)
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    typealias Emoji = EmojiArt.Emoji
    
    private var fetchTask: Task<(), Never>?
    
    @Published private var emojisArt = EmojiArt() {
        didSet {
//            autosave()
            if emojisArt.background != oldValue.background {
                fetchTask?.cancel()
                fetchTask = Task {
                    await fetchBackgroundImage()
                }
            }
        }
    }
    
    // MARK: - autosave
//    private let autosaveURL = URL.documentsDirectory.appendingPathComponent("autosave.emojiart")
//    private func autosave() {
//        print("autosave to \(autosaveURL)")
//        save(to: autosaveURL)
//    }
//    private func save(to: URL) {
//        do {
//            let data = try emojisArt.json()
////            print("autosave data:: \(String(data: data, encoding: .utf8) ?? "nil")")
//            try data.write(to: to)
//        } catch let error {
//            print("Autosave has error: \(error.localizedDescription)")
//        }
//    }
    
    var emojis: [Emoji] { emojisArt.emojis }
    
    init() {
//        if let data = try? Data(contentsOf: autosaveURL)
//            , let autosavedEmojiArt = try? EmojiArt(json: data) {
//            self.emojisArt = autosavedEmojiArt
//        }
    }
    
    // MARK: - Background Image
    @MainActor
    private func fetchBackgroundImage() async {
        if let url = emojisArt.background {
            background = .fetching(url)
            do {
                background = .found(try await fetchUIImage(url))
            } catch let error {
                background = .failed("Could not set background: \(error.localizedDescription)")
            }
        } else {
            background = .none
        }
    }
    
    private func fetchUIImage(_ url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let uiImage = UIImage(data: data) {
            return uiImage
        } else {
            throw FetchError.badImageData
        }
    }
    
    enum FetchError: Error {
        case badImageData
    }
    
    @Published var background: Background = .none
    
    enum Background {
        case none
        case fetching(URL)
        case found(UIImage)
        case failed(String)
        
        var uiImage: UIImage? {
            switch self {
            case .found(let uiImage): return uiImage
            default: return nil
            }
        }
        
        var urlBeingFetched: URL? {
            switch self {
            case .fetching(let url): return url
            default: return nil
            }
        }
        
        var isFetching: Bool { urlBeingFetched != nil }
        
        var failureReason: String? {
            switch self {
            case .failed(let reason): return reason
            default: return nil
            }
        }
    }
    
    var bbox: CGRect {
        var bbox = CGRect.zero
        for emoji in emojisArt.emojis {
            bbox = bbox.union(emoji.bbox)
        }
        if let backgroundSize = background.uiImage?.size {
            bbox = bbox.union(CGRect(center: .zero, size: backgroundSize))
        }
        return bbox
    }
    
    // MARK: - Intent(s)
    
    func undoablyPerform(_ action: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojisArt
        doit()
        undoManager?.registerUndo(withTarget: self) { myself in
            myself.undoablyPerform(action, with: undoManager) {
                myself.emojisArt = oldEmojiArt
            }
        }
        undoManager?.setActionName(action)
    }
    
    func setBackground(_ url: URL?, undoWith undoManager: UndoManager? = nil) {
        undoablyPerform("Set Background", with: undoManager) {
            emojisArt.background = url
        }
    }
    
    func addEmoji(_ emoji: String, at position: Emoji.Position, size: Int, undoWith undoManager: UndoManager? = nil) {
        undoablyPerform("Add \(emoji)", with: undoManager) {
            emojisArt.addEmoji(emoji, at: position, size: size)
        }
    }
    
    func move(_ emoji: Emoji, by offset: CGOffset) {
        let existingPosition = emojisArt[emoji].position
        emojisArt[emoji].position = Emoji.Position(
            x: existingPosition.x + Int(offset.width),
            y: existingPosition.y - Int(offset.height)
        )
    }
    
    func move(emojiWithId id: Emoji.ID, by offset: CGOffset) {
        if let emoji = emojisArt[id] {
            move(emoji, by: offset)
        }
    }
    
    func resize(_ emoji: Emoji, by scale: CGFloat) {
        emojisArt[emoji].size = Int(CGFloat(emojisArt[emoji].size) * scale)
    }
    
    func resize(emojiWithId id: Emoji.ID, by scale: CGFloat) {
        if let emoji = emojisArt[id] {
            resize(emoji, by: scale)
        }
    }
}


extension EmojiArt.Emoji {
    var font: Font {
        Font.system(size: CGFloat(self.size))
    }
    var bbox: CGRect {
        CGRect(
            center: position.in(nil),
            size: CGSize(width: CGFloat(size), height: CGFloat(size))
        )
    }
}

extension EmojiArt.Emoji.Position {
    func `in`(_ geometry: GeometryProxy?) -> CGPoint {
        let rect = geometry?.frame(in: .local) ?? .zero
        return CGPoint(x: rect.midX + CGFloat(x), y: rect.midY - CGFloat(y))
    }
    
    static func toEmojiPosition(dropAt location: CGPoint, geometry: GeometryProxy, zoom: CGFloat, pan: CGOffset) -> Self {
        let rect = geometry.frame(in: .local)
        return self.init(
            x: Int((location.x - rect.midX - pan.width) / zoom),
            y: -Int((location.y - rect.midY - pan.height) / zoom)
        )
    }
}
