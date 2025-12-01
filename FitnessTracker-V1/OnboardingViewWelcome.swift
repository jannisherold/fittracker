import SwiftUI

struct OnboardingViewWelcome: View {
    @State private var animate: Bool = false
    

    var body: some View {
        ScrollView{
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 90, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
                
                Text("Willkommen bei progress.")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.1), value: animate)
                
                Text("Tracke Deine Workouts, steigere Deine Kraft und behalte Deinen Fortschritt im Blick.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.2), value: animate)
                
                Spacer()
            }
            .onAppear {
                animate = true
            }
        }
        
        
    }
}

struct OnboardingViewWelcome_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingViewWelcome()
    }
}
