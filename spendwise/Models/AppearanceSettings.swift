//
//  AppearanceSettings.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Combine
import SwiftUI

enum AppearanceOption: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppearanceSettings: ObservableObject {
    private enum Keys {
        static let option = "spendwise.appearance.option"
        static let haptics = "spendwise.settings.haptics"
        static let autoSave = "spendwise.settings.autoSaveScans"
    }

    @Published var option: AppearanceOption {
        didSet { UserDefaults.standard.set(option.rawValue, forKey: Keys.option) }
    }

    @Published var enableHaptics: Bool {
        didSet { UserDefaults.standard.set(enableHaptics, forKey: Keys.haptics) }
    }

    @Published var autoSaveScans: Bool {
        didSet { UserDefaults.standard.set(autoSaveScans, forKey: Keys.autoSave) }
    }

    init() {
        let defaults = UserDefaults.standard
        let storedOption = defaults.string(forKey: Keys.option) ?? AppearanceOption.system.rawValue
        option = AppearanceOption(rawValue: storedOption) ?? .system
        enableHaptics = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        autoSaveScans = defaults.object(forKey: Keys.autoSave) as? Bool ?? true
    }
}
