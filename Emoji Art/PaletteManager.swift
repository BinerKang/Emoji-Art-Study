//
//  PaletteManager.swift
//  Emoji Art
//
//  Created by JackKong on 2023/8/26.
//

import SwiftUI

struct PaletteManager: View {
    let stores: [PaletteStore]
    
    @State private var selectedStore: PaletteStore?
    
    var body: some View {
        NavigationSplitView {
            List(stores, selection: $selectedStore) { store in
                Text(store.name) // bad !!!
                    .tag(store)
            }
        } content: {
            if let selectedStore {
                PaletteList(store: selectedStore)
            }
            Text("Choose a store")
        } detail: {
        
            Text("Choose a palette")
        }
    }
}

//struct PaletteManager_Previews: PreviewProvider {
//    static var previews: some View {
//        PaletteManager()
//    }
//}
