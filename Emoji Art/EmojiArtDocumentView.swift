//
//  EmojiArtDocumentView.swift
//  Emoji Art
//
//  Created by JackKong on 2023/8/24.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    typealias Emoji = EmojiArtDocument.Emoji
    @ObservedObject var document: EmojiArtDocument
    @Environment(\.undoManager) var undoManager
    
    @StateObject var store: PaletteStore = PaletteStore("Shared")
    
    // @ScaledMetric Follow System font scale
    @ScaledMetric private var paletteEmojiSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser()
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
        .toolbar {
            UndoButton()
        }
        .environmentObject(store)
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                documentContent(in: geometry)
                    .scaleEffect(zoom * gestureZoom)
                    .offset(pan + gesturePan)
            }
            .gesture(panGesture.simultaneously(with: pinchGesture))
            .onTapGesture(count: 2) {
                zoomToFit(document.bbox.size, in: geometry)
            }
            .dropDestination(for: Sturldata.self) { sturldatas, location in
                drop(sturldatas: sturldatas, at: location, in: geometry)
            }
            .onChange(of: document.background.failureReason) { reason in
                showBgFailureAlert = reason != nil
            }
            .onChange(of: document.background.uiImage) { uiImage in
                zoomToFit(uiImage?.size, in: geometry)
            }
            .alert(
                "Set Background",
                isPresented: $showBgFailureAlert,
                presenting: document.background.failureReason,
                actions: { _ in
                    Button("好 的", role: .cancel) { }
                } ,
                message: { reason in
                    Text(reason)
                }
            )
        }
    }
    
    // MARK: - Zoom to fit
    private func zoomToFit(_ size: CGSize?, in geometry: GeometryProxy) {
        if let size {
            zoomToFit(CGRect(center: .zero, size: size), in: geometry)
        }
    }
    
    private func zoomToFit(_ rect: CGRect, in geometry: GeometryProxy) {
        withAnimation {
            if rect.size.width > 0, rect.size.height > 0,
               geometry.size.width > 0, geometry.size.height > 0 {
                let hZoom = geometry.size.width / rect.size.width
                let vZoom = geometry.size.height / rect.size.height
                zoom = min(hZoom, vZoom)
                pan = CGOffset(
                    width: -rect.midX * zoom,
                    height: -rect.midY * zoom
                )
            }
        }
    }
    
    // MARK: - Zoom
    
    @State private var zoom: CGFloat = 1
    @GestureState private var gestureZoom: CGFloat = 1
    
    var pinchGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { inMotionScale, gestureZoom, _ in
                gestureZoom = inMotionScale
            }
            .onEnded { endingPinchScale in
                zoom *= endingPinchScale
            }
    }
    
    // MARK: - Pan
    
    @State private var pan: CGOffset = .zero
    @GestureState private var gesturePan: CGOffset = .zero
    
    var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePan) { value, gesturePan, _ in
                gesturePan = value.translation
            }
            .onEnded { value in
                pan += value.translation
            }
    }
    
    @ViewBuilder
    private func documentContent(in geometry: GeometryProxy) -> some View {
//        AsyncImage(url: document.background) { phase in
//            if let image = phase.image {
//                image
//            } else if let url = document.background {
//                if phase.error != nil {
//                    Text("\(url)")
//                } else {
//                    ProgressView()
//                }
//            }
//        }
        background
            .position(EmojiArt.Emoji.Position.zero.in(geometry))
        ForEach(document.emojis) { emoji in
            Text(emoji.string)
                .font(emoji.font)
                .position(emoji.position.in(geometry))
        }
    }
     
    @State private var showBgFailureAlert = false
    
    @ViewBuilder
    private var background: some View {
        if let uiImage = document.background.uiImage {
            Image(uiImage: uiImage)
        } else if(document.background.isFetching) {
            ProgressView()
                .scaleEffect(2)
                .tint(.blue)
        }
    }
    
    private func drop(sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for sturldata in sturldatas {
            switch sturldata {
            case .url(let url):
                document.setBackground(url, undoWith: undoManager)
                return true
            case .string(let string):
                document.addEmoji(
                    string,
                    at: Emoji.Position.toEmojiPosition(dropAt: location, geometry: geometry, zoom: zoom, pan: pan),
                    size: Int(paletteEmojiSize / zoom),
                    undoWith: undoManager
                )
                return true
            default:
                break;
            }
        }
        return false
    }
}


struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        let document = EmojiArtDocument()
        EmojiArtDocumentView(document: document)
    }
}
