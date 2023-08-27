//
//  Emoji_ArtApp.swift
//  Emoji Art
//
//  Created by JackKong on 2023/8/24.
//

import SwiftUI

@main
struct Emoji_ArtApp: App {
    @StateObject var defaultDocument = EmojiArtDocument()
//    @StateObject var store = PaletteStore("Main") // will share all documents
//    @StateObject var store1 = PaletteStore("Second")
//    @StateObject var store2 = PaletteStore("Third")
    
    var body: some Scene {
        DocumentGroup(newDocument: { defaultDocument } ) { config in
//            PaletteManager(stores: [store, store1, store2])
            EmojiArtDocumentView(document: config.document )
//                .environmentObject(store)
        }
    }
}
