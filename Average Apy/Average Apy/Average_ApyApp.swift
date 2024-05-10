//
//  Average_ApyApp.swift
//  Average Apy
//
//  Created by water on 3/30/24.
//

import SwiftUI

@main
struct Average_ApyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
