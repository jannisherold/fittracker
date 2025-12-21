//
//  MailCodeView.swift
//  FitnessTracker-V1
//
//  Created by Jannis Herold on 21.12.25.
//

import SwiftUI
import AuthenticationServices

struct MailCodeView: View {
    @StateObject private var appleVM = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var hasAcceptedLegal: Bool = false

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private var canCreateAccount: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6 &&
        hasAcceptedLegal &&
        !isLoading
    }

    var body: some View {
        
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {

                        // ───────── TOP: fix ─────────
                        Text("E-Mail Bestätigen")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.top, 24)
                        
                        Text("Du erhälst von uns eine E-Mail mit einem Bestätigungscode. Dies kann bis zu 5 Minuten dauern, bitte überprüfe auch deinen Spamordner")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        // der dynamische Abstand
                        Spacer(minLength: 0)

                        VStack(spacing: 18){
                            

                           

                            TextField("E-Mail Adresse", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .padding(14)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.horizontal, 24)

                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("6-stelliger Code", text: $password)
                                    .textContentType(.newPassword)
                                    .padding(14)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                
                            }
                            .padding(.horizontal, 24)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        
                        Spacer(minLength: 0)
                        
                        
                        
                        // ───────── BOTTOM: "klebt" unten ─────────
                        VStack(spacing: 18) {

                            

                            Button {
                                Task { await createAccount() }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isLoading {
                                        ProgressView()
                                    } else {
                                        Text("Bestätigen")
                                            .fontWeight(.semibold)
                                    }
                                    Spacer()
                                }
                                .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canCreateAccount)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)

                            Text("Durch erstellen eines Accounts stimmst du unseren AGB und der Datenschutzerklärung zu.")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            HStack(spacing: 6) {
                                Text("Du hast bereits einen Account?")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)

                                NavigationLink {
                                    OnboardingView()
                                } label: {
                                    Text("Einloggen")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.top, -6)
                            .padding(.bottom, 6)
                        }
                        .padding(.bottom, 40)
                    }
                    // 👇 DER entscheidende Punkt: Content bekommt Bildschirmhöhe
                    .frame(minHeight: geo.size.height, alignment: .top)
                }
                
            }
        
    }


    @MainActor
    private func createAccount() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await auth.signUpWithEmail(email: trimmedEmail, password: password)

            // Wenn SignUp eine Session erzeugt hat oder restoreSession erfolgreich war:
            if auth.isLoggedIn {
                hasCompletedOnboarding = true
            } else {
                // Falls du in Supabase "Confirm Email" aktiviert hast,
                // kann es sein, dass noch keine Session existiert.
                errorMessage = "Account erstellt. Bitte prüfe ggf. deine E-Mail zur Bestätigung und melde dich danach an."
            }
        } catch {
            errorMessage = "Registrierung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}


#Preview("Light Mode") {
    MailCodeView()
        .environmentObject(SupabaseAuthManager())
}

#Preview("Dark Mode") {
    MailCodeView()
        .environmentObject(SupabaseAuthManager())
        .preferredColorScheme(.dark)
}


