import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Konto
                Section("Konto") {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Profil")
                            /*Text("Abmelden, Profil löschen")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)*/
                        }
                    }
                    NavigationLink {
                        AppSettingsView()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App-Einstellungen")
                            /*Text("Einheiten (kg/lbs), Sprache, iCloud-Sync")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)*/
                        }
                    }
                }

                // MARK: - Support
                Section("Support") {
                    NavigationLink {
                        FeedbackSupportView()
                    } label: {
                        Text("Feedback & Support")
                    }
                    NavigationLink {
                        SocialMediaView()
                    } label: {
                        Text("Social-Media")
                    }
                }

                // MARK: - Rechtliches
                Section("Rechtliches") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("Version")
                    }

                    NavigationLink {
                        DatenschutzView()
                    } label: {
                        Text("Datenschutzerklärung")
                    }

                    NavigationLink {
                        AGBView()
                    } label: {
                        Text("AGB")
                    }
                    
                    NavigationLink {
                        ImpressumView()
                    } label: {
                        Text("Impressum")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Einstellungen")
        }
    }
}

// MARK: - Dummy Detail-Views (Platzhalter)

private struct ProfileSettingsView: View {
    var body: some View {
        List {
            Section {
                Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                Label("Profil löschen", systemImage: "trash")
            } footer: {
                Text("Dies sind Platzhalter. Wir füllen die Funktionen später.")
            }
        }
        .navigationTitle("Profil")
    }
}

private struct AppSettingsView: View {
    var body: some View {
        List {
            Section("Einheiten") {
                Label("kg / lbs (Platzhalter)", systemImage: "scalemass")
            }
            Section("Sprache") {
                Label("Sprache wählen (Platzhalter)", systemImage: "globe")
            }
            Section("iCloud-Sync") {
                Label("Sync aktivieren/deaktivieren (Platzhalter)", systemImage: "icloud")
            }
        }
        .navigationTitle("App-Einstellungen")
    }
}

private struct FeedbackSupportView: View {
    var body: some View {
        List {
            Section {
                Label("Feedback senden (Platzhalter)", systemImage: "paperplane")
                Label("Support kontaktieren (Platzhalter)", systemImage: "lifepreserver")
            }
        }
        .navigationTitle("Feedback & Support")
    }
}

private struct SocialMediaView: View {
    var body: some View {
        List {
            Section {
                Label("Instagram (Platzhalter)", systemImage: "camera")
                Label("X/Twitter (Platzhalter)", systemImage: "bird")
                Label("LinkedIn (Platzhalter)", systemImage: "link")
            }
        }
        .navigationTitle("Socialmedia")
    }
}

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                Label("App-Version 1.0.0 (Platzhalter)", systemImage: "info.circle")
            } footer: {
                Text("Hier werden später Informationen über die App angezeigt.")
            }
        }
        .navigationTitle("Version / About")
    }
}

private struct ImpressumView: View {
    var body: some View {
        List {
            Section {
                Label("Impressum (Platzhalter)", systemImage: "doc.text")
            } footer: {
                Text("Hier folgt später das Impressum gemäß §5 TMG.")
            }
        }
        .navigationTitle("Impressum")
    }
}

private struct DatenschutzView: View {
    var body: some View {
        List {
            Section {
                Label("Datenschutzerklärung (Platzhalter)", systemImage: "lock.shield")
            } footer: {
                Text("Hier wird die Datenschutzerklärung ergänzt.")
            }
        }
        .navigationTitle("Datenschutzerklärung")
    }
}

private struct AGBView: View {
    var body: some View {
        List {
            Section {
                Label("AGB (Platzhalter)", systemImage: "doc.plaintext")
            } footer: {
                Text("Hier werden die Allgemeinen Geschäftsbedingungen angezeigt.")
            }
        }
        .navigationTitle("AGB")
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(Store()) // Dummy, damit Preview funktioniert
}
