//
//  PaletteChooser.swift
//  Emoji Art
//
//  Created by JackKong on 2023/8/25.
//

import SwiftUI

struct PaletteChooser: View {
    @EnvironmentObject var store: PaletteStore
    @State var showPaletteEditor = false
    @State var showPaletteList = false
    
    var body: some View {
        HStack {
            chooser
            view(for: store.palettes[store.cursorIndex])
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditor(palette: $store.palettes[store.cursorIndex])
                        .font(nil)
                }
        }
        .clipped()
        .sheet(isPresented: $showPaletteList) {
            NavigationStack {
                PaletteList(store: store)
                    .font(nil)
            }
        }
        
    }
    
    var chooser: some View {
        AnimatedActionButton(systemImage: "paintpalette") {
            store.cursorIndex += 1
        }
        .contextMenu {
            gotoMenu
            AnimatedActionButton("添 加", systemImage: "plus.circle") {
                store.insert(Palette(name: "", emojis: ""))
                showPaletteEditor = true
            }
            AnimatedActionButton("删 除", systemImage: "minus.circle", role: .destructive) {
                store.palettes.remove(at: store.cursorIndex)
            }
            AnimatedActionButton("编 辑", systemImage: "pencil") {
                showPaletteEditor = true
            }
            AnimatedActionButton("列 表 管 理", systemImage: "list.bullet.rectangle.portrait") {
                showPaletteList = true
            }
        }
    }
    
    var gotoMenu: some View {
        Menu {
            ForEach(store.palettes) { palette in
                AnimatedActionButton(palette.name) {
                    if let index = store.palettes.firstIndex(where: {$0.id == palette.id}) {
                        store.cursorIndex = index
                    }
                }
            }
        } label: {
            Label("切 换", systemImage: "text.insert")
        }
    }
    
    func view(for palette: Palette) -> some View {
        HStack {
            Text(palette.name)
            ScrollingEmojis(palette.emojis)
        }
        .id(palette.id)
        .transition(AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
    }
}

struct ScrollingEmojis: View {
    let emojis: [String]
    
    init(_ emojis: String) {
        self.emojis = emojis.uniqued.map(String.init)
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .draggable(emoji)
                }
            }
        }
    }
}


struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        let store = PaletteStore("preview")
        PaletteChooser()
            .environmentObject(store)
    }
}
