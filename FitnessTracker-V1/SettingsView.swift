// SettingsView.swift
import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var store: Store
  @EnvironmentObject var auth: AuthViewModel
  @State private var showDelete = false

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Account")) {
          Button("Abmelden") {
            // Optional: lokale Daten pro Nutzer trennen/aufräumen
            // store.trainings.removeAll()
            auth.signOut()
          }
          Button("Account löschen", role: .destructive) {
            showDelete = true
          }
        }
      }
      .navigationTitle("Settings")
      .confirmationDialog("Account wirklich löschen?",
                          isPresented: $showDelete,
                          titleVisibility: .visible) {
        Button("Löschen", role: .destructive) {
          // Optional: store.trainings.removeAll()
          auth.deleteAccount { _ in }
        }
        Button("Abbrechen", role: .cancel) {}
      }
    }
  }
}
