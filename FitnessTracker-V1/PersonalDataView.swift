import SwiftUI

struct PersonalDataView: View {
    
    
    var body: some View {
        List {
            
            
            // --- Inhalt wie bisher (nur Layout angepasst) ---
            Section{
                
                
                
                HStack {
                    Text("Ziel")
                    Spacer()
                    
                }
                
                HStack {
                    Text("Abonnement verwalten")
                    Spacer()
                    
                }
                
                
            }
            
            Section {
                
                HStack {
                    Text("Kontakt E-Mail Adresse ändern")
                    Spacer()
                    
                }
                
                HStack {
                    Text("Körpergewicht zurücksetzen")
                    Spacer()
                    
                }
                
                HStack {
                    Text("Account löschen")
                    Spacer()
                    
                }
            }
            
        }
    }
}
