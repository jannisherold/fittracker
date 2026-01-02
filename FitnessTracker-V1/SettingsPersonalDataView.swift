import SwiftUI

struct SettingsPersonalDataView: View {
    
    
    var body: some View {
        List {
            
            
            
            
            Section {
                
                HStack {
                    Text("Namen ändern")
                    Spacer()
                    
                }
                
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
