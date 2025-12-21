import SwiftUI
import AuthenticationServices

struct MailCodeView: View {
    @EnvironmentObject private var auth: SupabaseAuthManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    let email: String
    let desiredPassword: String

    @State private var code: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var canConfirm: Bool {
        code.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6 && !isLoading
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("E-Mail bestätigen")
                .font(.title).fontWeight(.semibold)

            Text("Bitte gib den 6-stelligen Code aus deiner E-Mail ein.")
                .font(.caption2).foregroundColor(.secondary)

            TextField("6-stelliger Code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 24)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Button {
                Task { await confirm() }
            } label: {
                HStack {
                    Spacer()
                    if isLoading { ProgressView() } else { Text("Bestätigen").fontWeight(.semibold) }
                    Spacer()
                }
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canConfirm)
            .padding(.horizontal, 24)
        }
    }

    @MainActor
    private func confirm() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.verifyEmailOTP(email: email, code: code)
            try await auth.setPassword(desiredPassword)

            // Jetzt ist Session sicher da → Login fertig
            hasCompletedOnboarding = true
        } catch {
            errorMessage = "Bestätigung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}





