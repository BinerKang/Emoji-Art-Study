//
//  PaletteList.swift
//  Emoji Art
//
//  Created by JackKong on 2023/8/25.
//

import SwiftUI

struct PaletteList: View {
    @ObservedObject var store: PaletteStore
    @State private var showCursorPaletteEditor = false
    
    var body: some View {
            List {
                ForEach(store.palettes) { palette in
                    NavigationLink(value: palette.id) {
                        VStack(alignment: .leading) {
                            Text(palette.name)
                            Text(palette.emojis).lineLimit(1)
                        }
                    }
                }
                .onDelete { indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newIndex in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newIndex)
                }
            }
            .navigationDestination(for: Palette.ID.self) { paletteId in
//                PaletteView(palette: palette)
                if let index = store.palettes.firstIndex(where: { $0.id == paletteId}) {
                    PaletteEditor(palette: $store.palettes[index])
                }
            }
            .navigationDestination(isPresented: $showCursorPaletteEditor) {
                PaletteEditor(palette: $store.palettes[store.cursorIndex])
            }
            .navigationTitle("\(store.name) Palette")
            .toolbar {
                Button {
                    store.insert(name: "", emojis: "")
                    showCursorPaletteEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        
    }
}

struct PaletteView: View {
    let palette: Palette
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(palette.emojis.uniqued.map{ String($0) }, id: \.self) { emoji in
                    NavigationLink(value: emoji) {
                        Text(emoji)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .font(.largeTitle)
        .navigationDestination(for: String.self) { emoji in
            Text(emoji)
                .font(.system(size: 300))
        }
        .navigationTitle(palette.name)
    }
}

//struct PaletteList_Previews: PreviewProvider {
//    static var previews: some View {
//        PaletteList()
//    }
//}
