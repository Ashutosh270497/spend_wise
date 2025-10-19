//
//  AuthManager.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import Combine
import CryptoKit
import Foundation

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var currentUser: UserSession?
    @Published private(set) var errorMessage: String?

    private let storageKey = "spendwise.auth.users"
    private let sessionKey = "spendwise.auth.currentUserEmail"

    private var storedUsers: [StoredUser] = []

    private init() {
        loadUsers()
        restoreSession()
    }

    func register(name: String, email: String, password: String) -> Bool {
        let normalizedEmail = email.lowercased()
        guard !name.isEmpty, !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return false
        }

        guard !storedUsers.contains(where: { $0.email == normalizedEmail }) else {
            errorMessage = "An account with this email already exists."
            return false
        }

        let hashedPassword = hash(password: password)
        let user = StoredUser(name: name, email: normalizedEmail, passwordHash: hashedPassword)
        storedUsers.append(user)
        persistUsers()

        currentUser = UserSession(name: name, email: normalizedEmail)
        saveSession()
        errorMessage = nil
        return true
    }

    func login(email: String, password: String) -> Bool {
        let normalizedEmail = email.lowercased()
        guard let user = storedUsers.first(where: { $0.email == normalizedEmail }) else {
            errorMessage = "No account found for this email."
            return false
        }

        let hashedPassword = hash(password: password)
        guard user.passwordHash == hashedPassword else {
            errorMessage = "Incorrect password."
            return false
        }

        currentUser = UserSession(name: user.name, email: user.email)
        saveSession()
        errorMessage = nil
        return true
    }

    func logout() {
        currentUser = nil
        errorMessage = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func clearError() {
        errorMessage = nil
    }

    private func hash(password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func loadUsers() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            storedUsers = try JSONDecoder().decode([StoredUser].self, from: data)
        } catch {
            storedUsers = []
        }
    }

    private func persistUsers() {
        do {
            let data = try JSONEncoder().encode(storedUsers)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            errorMessage = "Failed to save account."
        }
    }

    private func saveSession() {
        UserDefaults.standard.set(currentUser?.email, forKey: sessionKey)
    }

    private func restoreSession() {
        guard let email = UserDefaults.standard.string(forKey: sessionKey),
              let user = storedUsers.first(where: { $0.email == email }) else { return }
        currentUser = UserSession(name: user.name, email: user.email)
    }
}

private struct StoredUser: Codable {
    let name: String
    let email: String
    let passwordHash: String
}
