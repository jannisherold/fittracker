import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentIndex: Int = 0
    
    private let totalPages: Int = 3
    
    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Swipebarer Inhalt – nur die SubViews werden hier eingebunden
                TabView(selection: $currentIndex) {
                    OnboardingViewWelcome()
                        .tag(0)
                    
                    OnboardingViewGoals()
                        .tag(1)
                    
                    OnboardingViewFeatures(onFinish: finishOnboarding)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentIndex)
                
                // Unterer Weiter-/Loslegen-Button (optional zusätzlich zum Swipen)
                bottomButton
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
        
        
        Button(action: {
            if currentIndex < totalPages - 1 {
                currentIndex += 1
            } else {
                finishOnboarding()
            }
        }) {
            Text(currentIndex < totalPages - 1 ? "Weiter" : "Loslegen")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
    }
    
    private func finishOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
