import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Kurz-Header
                VStack(spacing: 6) {
                    Text("Progress+")
                        .font(.title).bold()

                    Text("Schalte alle Fortschrittsanalysen frei.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Feature-Liste (deine Premium-Features aus ProgressView)
                List {
                    Section("Enthalten in Progress+") {
                        Label("Kraft", systemImage: "chart.line.uptrend.xyaxis")
                        Label("Statistik", systemImage: "chart.bar.xaxis")
                        Label("Körpergewicht", systemImage: "scalemass")
                        Label("Trainingsfrequenz", systemImage: "calendar")
                        Label("Trainingshistorie", systemImage: "clock.arrow.circlepath")
                    }

                    Section {
                        if purchases.isPremium {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Text("Progress+ ist aktiv")
                                Spacer()
                            }
                        } else {
                            // Apple-provided StoreKit UI (StoreKit 2)
                            SubscriptionStoreView(productIDs: [
                                PurchaseManager.ProductID.monthly,
                                PurchaseManager.ProductID.yearly
                            ])
                            .subscriptionStoreControlStyle(.prominentPicker)
                            .subscriptionStoreButtonLabel(.price)
                            .subscriptionStorePickerItemBackground(.thinMaterial)
                        }
                    }

                    Section {
                        Button("Käufe aktualisieren") {
                            Task { await purchases.refreshEntitlements() }
                        }

                        Button("Abo verwalten") {
                            Task { await openManageSubscriptions() }
                        }
                    } footer: {
                        Text("Kündigung, Abrechnung und Verwaltung erfolgen über Apple. Der Premium-Status wird direkt aus den App Store-Entitlements bestimmt.")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }

    private func openManageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        do {
            try await AppStore.showManageSubscriptions(in: scene)
        } catch {
            // bewusst still: best-effort; UI soll nicht "kaputt" wirken
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
