import SwiftUI

struct AuthView: View {
  @EnvironmentObject var auth: AuthViewModel
  @State private var email = ""
  @State private var password = ""
  @State private var isSignUp = false
  @State private var showResetAlert = false

  var body: some View {
    VStack(spacing: 16) {
      Text("progress.").font(.largeTitle).bold().padding(.top, 24)

      Group {
        TextField("E-Mail", text: $email)
          .textInputAutocapitalization(.never)
          .keyboardType(.emailAddress)
          .autocorrectionDisabled()
          .padding().background(Color(.secondarySystemBackground)).cornerRadius(10)

        SecureField("Passwort", text: $password)
          .padding().background(Color(.secondarySystemBackground)).cornerRadius(10)

        Button {
          isSignUp ? auth.signUp(email: email, password: password)
                   : auth.signIn(email: email, password: password)
        } label: {
          HStack { Spacer(); Text(isSignUp ? "Registrieren" : "Anmelden").bold(); Spacer() }
        }
        .disabled(auth.isBusy || email.isEmpty || password.isEmpty)
        .padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)

        Button("Passwort vergessen?") {
          guard !email.isEmpty else { showResetAlert = true; return }
          auth.sendPasswordReset(email: email)
        }
        .font(.footnote)
      }
      .padding(.horizontal)

      Toggle(isOn: $isSignUp) { Text(isSignUp ? "Modus: Registrieren" : "Modus: Anmelden") }
        .padding(.horizontal)

      if let error = auth.errorMessage {
        Text(error).font(.footnote).foregroundColor(.red)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }

      Spacer()
    }
    .alert("Bitte E-Mail eingeben", isPresented: $showResetAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("Gib oben deine E-Mail ein, damit wir einen Reset-Link schicken können.")
    }
  }
}
