import SwiftUI
import StoreKit

struct SettingsAboView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: purchases.isPremium ? "checkmark.seal.fill" : "lock.fill")
                        .foregroundStyle(purchases.isPremium ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(purchases.isPremium ? "Progress+ ist aktiv" : "Progress+ ist nicht aktiv")
                            .font(.headline)

                        if let date = purchases.lastEntitlementRefresh {
                            Text("Zuletzt geprüft: \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Premium-Status wird über Apple geprüft.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 6)
            }

            Section {
                if purchases.isPremium {
                    Button("Abo verwalten") {
                        Task { await openManageSubscriptions() }
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Text("Progress+ freischalten")
                            Spacer()
                            Text("Upgrade")
                                .foregroundStyle(.blue)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }

                Button("Käufe aktualisieren") {
                    Task { await purchases.refreshEntitlements() }
                }
            } header: {
                Text("Aktionen")
            } footer: {
                Text("Käufe, Verlängerungen und Kündigung werden über den App Store verwaltet. Der Premium-Status wird direkt aus den StoreKit-Entitlements bestimmt.")
            }
        }
        .navigationTitle("Abo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchases)
        }
        
    }

    private func openManageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        do {
            try await AppStore.showManageSubscriptions(in: scene)
        } catch {
            // bewusst still: best-effort
        }
    }
}
