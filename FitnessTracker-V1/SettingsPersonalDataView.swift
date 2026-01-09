import SwiftUI

struct SettingsPersonalDataView: View {
    
    
    var body: some View {
        
        List {
            Section {
                
                
                HStack{
                    Text("Name")
                    
                    Spacer()
                    
                    Text("Vorname Nachname")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                    
                }
                
                HStack{
                    Text("Kontakt E-Mail")
                    
                    Spacer()
                    
                    Text("E-Mail")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                    
                }
                
                
                
                
                
                
            }
            
            Section{
                HStack {
                    Text("Körpergewichtsdaten zurücksetzen")
                    Spacer()
                    
                }
                
            }
            
            Section{
                HStack {
                    Text("Account löschen")
                    Spacer()
                    
                }
            }
            
        }
    }
}
