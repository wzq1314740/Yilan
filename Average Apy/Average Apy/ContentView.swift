//
//  ui_test.swift
//  Average Apy
//
//  Created by water on 3/30/24.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            tab_ApyView()
                .tabItem {
                    Label("APY", systemImage: "chart.xyaxis.line")
                }
                .tag(0)
//            tab_Testview()
//                .tabItem {
//                    Label("Test", systemImage: "square.and.arrow.up.fill")
//                }
//                .tag(1)
//            
//            tab_Testview1()
//                .tabItem {
//                    Label("Test1", systemImage: "square.and.arrow.up.fill")
//                }
//                .tag(2)
            
            tab_AssetView()
                .tabItem {
                    Label("My Asset", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
    }
    
}

#Preview {
    ContentView()
}
