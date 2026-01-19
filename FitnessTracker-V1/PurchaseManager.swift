import Foundation
import StoreKit

/// Apple = Source of Truth.
/// Liest Premium-Status ausschließlich aus StoreKit2 Entitlements.
@MainActor
final class PurchaseManager: ObservableObject {

    // MARK: - Public state

    @Published private(set) var isPremium: Bool = false
    @Published private(set) var lastEntitlementRefresh: Date?

    // MARK: - Product IDs (müssen 1:1 zu App Store Connect / StoreKit Config passen)

    enum ProductID {
        static let monthly = "progress_plus_monthly"
        static let yearly  = "progress_plus_yearly"

        static let all: Set<String> = [monthly, yearly]
    }

    // MARK: - Private

    private var updatesTask: Task<Void, Never>?

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Lifecycle

    /// Call once on app start (später in Schritt C im App-Entry).
    func start() {
        // Doppelstart verhindern
        if updatesTask != nil { return }

        // Initialer Status
        Task { await refreshEntitlements() }

        // Live-Updates (Renewals, Refunds/Revokes, etc.)
        updatesTask = Task { [weak self] in
            guard let self else { return }
            await self.listenForTransactionUpdates()
        }
    }

    /// Manuell auslösbar (z. B. Settings "Käufe aktualisieren")
    func refreshEntitlements() async {
        var premium = false

        // currentEntitlements liefert nur aktuell gültige Entitlements.
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard ProductID.all.contains(transaction.productID) else { continue }

            // Bei Auto-Renew Subscriptions ist "currentEntitlements" bereits gefiltert;
            // wenn es hier auftaucht, behandeln wir es als aktiv.
            premium = true
            break
        }

        isPremium = premium
        lastEntitlementRefresh = Date()
    }

    // MARK: - Updates stream

    private func listenForTransactionUpdates() async {
        for await update in Transaction.updates {
            // Wir akzeptieren nur verifizierte Transaktionen
            guard case .verified(let transaction) = update else { continue }

            // Nur unsere Produkte interessieren uns
            guard ProductID.all.contains(transaction.productID) else {
                // trotzdem finishen, um StoreKit nicht zu stauen
                await transaction.finish()
                continue
            }

            // Status neu berechnen (Source of Truth)
            await refreshEntitlements()

            // Wichtig: finish() nach Verarbeitung
            await transaction.finish()
        }
    }
}
