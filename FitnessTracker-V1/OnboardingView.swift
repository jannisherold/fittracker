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
                TabView(selection: $currentIndex) {
                    OnboardingViewWelcome()
                        .tag(0)

                    OnboardingViewGoals()
                        .tag(1)

                    OnboardingViewFeatures()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentIndex)
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    handlePrimaryButtonTap()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Text(primaryButtonTitle)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color(.systemBlue))
            }
        }
    }

    private var primaryButtonTitle: String {
        switch currentIndex {
        case 0: return "Starten"
        case 1: return "Weiter"
        default: return "Loslegen"
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
