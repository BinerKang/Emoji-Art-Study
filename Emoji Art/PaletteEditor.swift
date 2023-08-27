//
//  PaletteEditor.swift
//  Emoji Art
//
//  Created by JackKong on 2023/8/25.
//

import SwiftUI

struct PaletteEditor: View {
    @Binding var palette: Palette
    @State private var emojisToAdd = ""
    
    
    private let emojiFont = Font.system(size: 40)
    
    enum Focused {
        case name
        case add
    }
    
    @FocusState private var focused: Focused?
    
    var body: some View {
        Form {
            Section(header: Text("名 称")) {
                TextField("Name", text: $palette.name)
                    .focused($focused, equals: .name)
            }
            Section(header: Text("添 加")) {
                TextField("Add emojis", text: $emojisToAdd)
                    .focused($focused, equals: .add)
                    .font(emojiFont)
                    .onChange(of: emojisToAdd) { emojisToAdd in
                        palette.emojis = (emojisToAdd + palette.emojis)
                            .filter{ $0.isEmoji }
                            .uniqued
                    }
                   
                removeEmojis
            }
        }
        .frame(minWidth: 400, minHeight: 600)
        .onAppear {
            if palette.name.isEmpty {
                focused = .name
            } else {
                focused = .add
            }
        }
    }
    
    var removeEmojis: some View {
        VStack(alignment: .trailing) {
            Text("点击移除Emojis").font(.caption).foregroundColor(.gray)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(palette.emojis.uniqued.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .font(emojiFont)
                        .onTapGesture {
                            withAnimation {
                                palette.emojis.remove(emoji.first!)
                            }
                        }
                }
            }
        }
    }
}

struct PaletteEditor_Previews: PreviewProvider {
    struct Preview: View {
        @State private var palette = PaletteStore("Preview").palettes.first!
        var body: some View {
            PaletteEditor(palette: $palette)
        }
    }
    
    static var previews: some View {
        Preview()
    }
}
