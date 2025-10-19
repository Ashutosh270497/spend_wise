//
//  ContentView.swift
//  spendwise
//
//  Created by Ashutosh Tiwari on 18/10/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ExpenseStore
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appearanceSettings: AppearanceSettings
    @State private var isPresentingAddExpense = false
    @State private var selectedTab: Tab = .overview

    var body: some View {
        Group {
            if authManager.currentUser != nil {
                mainInterface
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                AuthenticationView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authManager.currentUser)
    }

    private var mainInterface: some View {
        TabView(selection: $selectedTab) {
            DashboardView(isPresentingAddExpense: $isPresentingAddExpense)
                .tabItem {
                    Label("Overview", systemImage: "rectangle.grid.2x2")
                }
                .tag(Tab.overview)

            ExpensesListView(isPresentingAddExpense: $isPresentingAddExpense)
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.expenses)

            CalendarRootView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .sheet(isPresented: $isPresentingAddExpense) {
            AddExpenseView { newExpense in
                store.addExpense(newExpense)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private enum Tab: Hashable {
        case overview
        case expenses
        case calendar
        case settings
    }
}

#Preview {
    ContentView()
        .environmentObject(ExpenseStore())
        .environmentObject(AuthManager.shared)
        .environmentObject(AppearanceSettings())
}
