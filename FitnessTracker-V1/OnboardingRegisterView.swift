import SwiftUI
import AuthenticationServices

struct OnboardingRegisterView: View {
    @StateObject private var appleVM = AuthViewModel()
    @EnvironmentObject private var auth: SupabaseAuthManager
    
    // Onboarding/Profile Persistenz (lokal)
    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("userName") private var storedName: String = ""
    @AppStorage("userGoal") private var storedGoal: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""      // kommt aus Screen 2
    @AppStorage("hasCreatedAccount") private var hasCreatedAccount: Bool = false
    
    @State private var errorMessage: String?
    
    var body: some View {
        
        
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    
                    Text("Registrieren")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 24)
                    
                    
                    Spacer(minLength: 0)
                    
                    VStack(spacing: 10) {
                        
                        SignInWithAppleButton(
                            .signUp,
                            onRequest: appleVM.handleSignInWithAppleRequest,
                            onCompletion: { result in
                                Task {
                                    do {
                                        let profile = try await appleVM.handleSignInWithAppleCompletionAndReturnProfile(
                                            result,
                                            authManager: auth
                                        )
                                        
                                        // ✅ Lokal speichern (MVP)
                                        storedEmail = profile.email
                                        storedName = profile.name
                                        storedGoal = onboardingGoal.isEmpty ? "Überspringen" : onboardingGoal
                                        
                                        // ✅ Flag, dass ein Account erstellt wurde
                                        hasCreatedAccount = true
                                        
                                        // ✅ Optional: in Supabase DB speichern (falls Tabelle existiert)
                                        await auth.upsertProfile(
                                            email: storedEmail,
                                            name: storedName,
                                            goal: storedGoal
                                        )
                                        
                                    } catch {
                                        errorMessage = "Apple Login fehlgeschlagen: \(error.localizedDescription)"
                                    }
                                }
                            }
                        )
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 24)
                        
                        /*
                         Text("Mit deiner Apple ID anmelden. Email+Passwort ist im MVP nicht verfügbar.")
                         .font(.footnote)
                         .foregroundStyle(.secondary)
                         .multilineTextAlignment(.center)
                         .padding(.horizontal, 32)
                         .padding(.top, 4)
                         */
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                        
                        
                    }
                    
                    //Spacer(minLength: 0)
                    
                    
                    //.padding(.bottom, 8)
                    
                    
                    
                    VStack(spacing: 12) {
                        
                        
                        HStack(spacing: 6) {
                            Text("Du hast bereits einen Account?")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Button {
                                // Nutzer hat schon einen Account -> AppRootView soll Login zeigen
                                hasCreatedAccount = true
                                hasCompletedOnboarding = true
                            } label: {
                                Text("Einloggen")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Text("Durch die Registrierung stimmst du unseren AGB und der Datenschutzerklärung zu.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                        //.padding(.bottom, 16)
                    }
                    //.padding(.bottom, 40)
                }
                .frame(minHeight: geo.size.height, alignment: .top)
            }
            
        }
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        
    }
    
}


// MARK: - Previews

#Preview("Light Mode") {
    OnboardingRegisterView()
        .environmentObject(SupabaseAuthManager())
}

#Preview("Dark Mode") {
    OnboardingRegisterView()
        .environmentObject(SupabaseAuthManager())
        .preferredColorScheme(.dark)
}
