//
//  spendwiseApp.swift
//  spendwise
//
//  Created by Ashutosh Tiwari on 18/10/25.
//

import SwiftUI

@main
struct spendwiseApp: App {
    @StateObject private var store = ExpenseStore()
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var appearance = AppearanceSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(authManager)
                .environmentObject(appearance)
                .preferredColorScheme(appearance.option.colorScheme)
        }
    }
}
