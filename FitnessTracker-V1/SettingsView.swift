import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Konto
                Section() {
                    NavigationLink {
                        SettingsProfileView()
                    } label: {
                        HStack(spacing: 10){
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 42, weight: .regular))
                                
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Profil")
                                    .font(.system(size: 20, weight: .semibold))
                                    
                                Text("Persönliche Daten, Abonnement und mehr")
                                    .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(.secondary)
                                      
                                        .foregroundColor(.secondary)
                            }
                        }
                            
                        
                    }
                    
                }

                // MARK: - App-Einstellungen
                Section() {
                    NavigationLink {
                        SettingsLanguageView()
                    } label: {
                        
                        HStack(spacing: 0) {
                           
                                Image(systemName: "globe")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    //.frame(width: 28, alignment: .leading)
                                    //.foregroundStyle(.blue)
                            }

                            Text("Sprache")
                                //.font(.system(size: 22, weight: .semibold))   // H2-ähnlich
                                //.foregroundColor(.primary)                     // Schwarz

                            Spacer()
                        
                       
                    }
                    
                    NavigationLink {
                        AppSettingsView()
                    } label: {
                        HStack(spacing: 0) {
                           
                                Image(systemName: "scalemass")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    //.frame(width: 28, alignment: .leading)
                                    //.foregroundStyle(.blue)
                            }

                            Text("Einheit")
                                //.font(.system(size: 22, weight: .semibold))   // H2-ähnlich
                                //.foregroundColor(.primary)                     // Schwarz

                            Spacer()
                    }
                    
                }

                /*
                //Kontakt/Socials
                Section() {
                    
                
                    NavigationLink {
                        FeedbackSupportView()
                    } label: {
                        Text("Kontakt")
                    }
                    
                    NavigationLink {
                        SocialMediaView()
                    } label: {
                        Text("Social-Media")
                    }
                }
                */
                
                // MARK: - Rechtliches
                Section() {
                    /*
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("Version")
                    }
                     */

                    

                    NavigationLink {
                        AGBView()
                    } label: {
                        Text("AGB")
                    }
                    
                    NavigationLink {
                        DatenschutzView()
                    } label: {
                        Text("Datenschutzerklärung")
                    }
                    
                    NavigationLink {
                        ImpressumView()
                    } label: {
                        Text("Impressum")
                    }
                    
                    NavigationLink {
                        FeedbackSupportView()
                    } label: {
                        Text("Kontakt")
                    }
                    
                
                }
                
                Section(){
                    Text("Soziale Medien Icons mit link als HStack")
                }
                .listRowBackground(Color.clear)
                
                Section(){
                    Text("Versionsnummer")
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.clear)
                
    
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Einstellungen")
        }
    }
}

// MARK: - Dummy Detail-Views (Platzhalter)



private struct AppSettingsView: View {
    var body: some View {
        List {
            Section("Einheit wählen") {
                Label("kg", systemImage: "scalemass")
                Label("lbs", systemImage: "scalemass")
            }
            
        }
        //.navigationTitle("App-Einstellungen")
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
