//
//  AuthenticationView.swift
//  spendwise
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AuthenticationView: View {
    @State private var isRegistering = true
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Spendwise")
                    .font(.largeTitle.weight(.bold))
                Text(isRegistering ? "Create your account to start tracking expenses." : "Welcome back. Sign in to continue managing your spending.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                if isRegistering {
#if canImport(UIKit)
                    FloatingField(
                        "Name",
                        text: $name,
                        systemImage: "person",
                        autocapitalization: .words,
                        textContentType: .name
                    )
#else
                    FloatingField(
                        "Name",
                        text: $name,
                        systemImage: "person",
                        autocapitalization: .words
                    )
#endif
                }
#if canImport(UIKit)
                FloatingField(
                    "Email",
                    text: $email,
                    systemImage: "envelope",
                    keyboard: .emailAddress,
                    autocapitalization: .never,
                    textContentType: .emailAddress
                )
#else
                FloatingField(
                    "Email",
                    text: $email,
                    systemImage: "envelope",
                    keyboard: .emailAddress,
                    autocapitalization: .never
                )
#endif
                FloatingSecureField("Password", text: $password, systemImage: "lock")
            }
            .padding(24)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 12)

            if let message = authManager.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Button(action: submit) {
                Text(isRegistering ? "Create Account" : "Sign In")
                    .font(.headline)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundColor(.white)
                    .shadow(color: Color.accentColor.opacity(0.25), radius: 12, x: 0, y: 8)
            }
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1 : 0.5)

            Button {
                withAnimation(.spring) {
                    isRegistering.toggle()
                    authManager.clearError()
                }
            } label: {
                Text(isRegistering ? "Already have an account? Sign in" : "Need an account? Register")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 80)
        .background(
            LinearGradient(colors: [.blue.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private var isFormValid: Bool {
        if isRegistering {
            return !name.isEmpty && email.contains("@") && password.count >= 6
        }
        return email.contains("@") && password.count >= 6
    }

    private func submit() {
        if isRegistering {
            if authManager.register(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                    password: password) {
                clearFields()
            }
        } else {
            _ = authManager.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                  password: password)
        }
    }

    private func clearFields() {
        name = ""
        email = ""
        password = ""
    }
}

private struct FloatingField: View {
    var label: LocalizedStringKey
    @Binding var text: String
    var systemImage: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
#if canImport(UIKit)
    var textContentType: UITextContentType? = nil
#endif

    init(
        _ label: LocalizedStringKey,
        text: Binding<String>,
        systemImage: String,
        keyboard: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .words
    ) {
        self.label = label
        self._text = text
        self.systemImage = systemImage
        self.keyboard = keyboard
        self.autocapitalization = autocapitalization
#if canImport(UIKit)
        self.textContentType = nil
#endif
    }

#if canImport(UIKit)
    init(
        _ label: LocalizedStringKey,
        text: Binding<String>,
        systemImage: String,
        keyboard: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .words,
        textContentType: UITextContentType?
    ) {
        self.init(
            label,
            text: text,
            systemImage: systemImage,
            keyboard: keyboard,
            autocapitalization: autocapitalization
        )
        self.textContentType = textContentType
    }
#endif

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            TextField(label, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
#if canImport(UIKit)
                .textContentType(textContentType)
#endif
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct FloatingSecureField: View {
    var label: LocalizedStringKey
    @Binding var text: String
    var systemImage: String
    @State private var isSecure = true

    init(_ label: LocalizedStringKey, text: Binding<String>, systemImage: String) {
        self.label = label
        self._text = text
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)

            Group {
                if isSecure {
                    SecureField(label, text: $text)
                } else {
                    TextField(label, text: $text)
                }
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
