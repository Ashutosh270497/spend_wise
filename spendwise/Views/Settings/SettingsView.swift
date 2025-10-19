//
//  SettingsView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appearanceSettings: AppearanceSettings

    var body: some View {
        NavigationStack {
            List {
                if let user = authManager.currentUser {
                    Section("Account") {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Text(user.name.prefix(1).uppercased())
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        Button(role: .destructive) {
                            authManager.logout()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Color Scheme", selection: $appearanceSettings.option) {
                        ForEach(AppearanceOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }

                    Toggle(isOn: $appearanceSettings.autoSaveScans) {
                        Label("Auto-save scanned receipts", systemImage: "doc.text.viewfinder")
                    }

                    Toggle(isOn: $appearanceSettings.enableHaptics) {
                        Label("Enable haptics", systemImage: "waveform.path.ecg")
                    }
                }

                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.appVersionString)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://www.apple.com/privacy/")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }
}

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
