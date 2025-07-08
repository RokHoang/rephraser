//
//  rephraser.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import SwiftUI

@main
struct rephraserApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Rephraser", systemImage: "text.badge.checkmark") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
