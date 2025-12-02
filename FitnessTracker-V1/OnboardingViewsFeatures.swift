import SwiftUI

struct OnboardingViewFeatures: View {
    //let onFinish: () -> Void
    @State private var animate: Bool = false
    
    var body: some View {
        
        ScrollView{
            VStack(spacing: 20) {
                Spacer(minLength: 40)
                
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 70))
                    .symbolRenderingMode(.hierarchical)
                    .opacity(animate ? 1.0 : 0.0)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
                
                Text("So hilft Dir die App")
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.1), value: animate)
                
                Text("Erstelle Workouts, tracke Gewichte und Wiederholungen und lass Dich von deinen Statistiken motivieren.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.15), value: animate)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "dumbbell.fill",
                        title: "Eigene Workouts",
                        text: "Erstelle und organisiere flexibel Deine Trainingspläne."
                    )
                    FeatureRow(
                        icon: "list.bullet.clipboard",
                        title: "Persönliches Logbuch",
                        text: "Halte fest, wie viel Du bewegst – Satz für Satz."
                    )
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Mit Premium: Fortschritt im Blick",
                        text: "Sieh, wie Du dich über Wochen und Monate steigerst."
                    )
                }
                .padding(.horizontal)
                .opacity(animate ? 1.0 : 0.0)
                .offset(y: animate ? 0 : 10)
                .animation(.easeOut.delay(0.2), value: animate)
                
                Spacer()
              
                
                Spacer(minLength: 24)
            }
            .onAppear {
                animate = true
            }
        }
        
        
    }
}

// Helper-View bleibt lokal in dieser Datei
struct FeatureRow: View {
    let icon: String
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct OnboardingViewFeatures_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingViewFeatures()
    }
}
