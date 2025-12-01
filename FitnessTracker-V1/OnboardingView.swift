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
            }
        }
        // Tabbar der App ausblenden, damit nur die Liquid-Glass-Bottom-Bar sichtbar ist
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                
                Button{
                    handlePrimaryButtonTap()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    if(currentIndex == 0){
                        Text("Starten")
                            .fontWeight(.semibold)
                    }
                    
                    else if(currentIndex == 1){
                        Text("Weiter")
                            .fontWeight(.semibold)
                    }
                    
                    if(currentIndex == 2){
                        Text("Loslegen")
                            .fontWeight(.semibold)
                    }
                    
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color(.systemBlue))
                    
                    
                    /*
                    Text(currentIndex < totalPages - 1 ? "Weiter" : "Loslegen")
                        .fontWeight(.semibold)
                    */
                
                
            }
        }
    }
    
    
    private func handlePrimaryButtonTap() {
        if currentIndex < totalPages - 1 {
            currentIndex += 1
        } else {
            finishOnboarding()
        }
    }
    
    private func finishOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView()
        }
    }
}
