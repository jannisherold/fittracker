import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentIndex: Int = 0
    
    private let steps: [OnboardingStep] = [
        OnboardingStep(
            id: 0,
            title: "Willkommen bei progress.",
            subtitle: "Tracke Deine Workouts, steigere Deine Kraft und behalte Deinen Fortschritt im Blick.",
            systemImage: "figure.strengthtraining.traditional"
        ),
        OnboardingStep(
            id: 1,
            title: "Was ist Dein Ziel?",
            subtitle: "Wähle aus, was auf Dich zutrifft – Du kannst es später jederzeit ändern.",
            systemImage: "target"
        ),
        OnboardingStep(
            id: 2,
            title: "So hilft Dir die App",
            subtitle: "Erstelle Workouts, tracke Gewichte und Wiederholungen und lass dich von deinen Statistiken motivieren.",
            systemImage: "chart.bar.xaxis"
        )
    ]
    
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
                // Swipebarer Inhalt
                TabView(selection: $currentIndex) {
                    OnboardingPageWelcome(step: steps[0])
                        .tag(0)
                    
                    OnboardingPageGoal(step: steps[1])
                        .tag(1)
                    
                    OnboardingPageFeatures(step: steps[2], onFinish: finishOnboarding)
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
    
    private var bottomButton: some View {
        Button(action: {
            if currentIndex < steps.count - 1 {
                currentIndex += 1
            } else {
                finishOnboarding()
            }
        }) {
            Text(currentIndex < steps.count - 1 ? "Weiter" : "Loslegen")
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

// MARK: - Model

struct OnboardingStep: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let systemImage: String
}

// MARK: - Einzelne Seiten

// Seite 1 – Welcome
struct OnboardingPageWelcome: View {
    let step: OnboardingStep
    @State private var animate: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: step.systemImage)
                .font(.system(size: 90, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(animate ? 1.0 : 0.8)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
            
            Text(step.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.easeOut.delay(0.1), value: animate)
            
            Text(step.subtitle)
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

// Seite 2 – Zielauswahl (animierte Karten)
struct OnboardingPageGoal: View {
    let step: OnboardingStep
    @State private var selectedGoal: String? = nil
    @State private var animate: Bool = false
    
    private let goals: [(title: String, systemImage: String)] = [
        
        ("Muskelaufbau", "dumbbell.fill"),
        ("Abnehmen", "arrow.down"),
        ("Mehr Kraft", "bolt.circle"),
        ("Fitter fühlen", "figure.walk.motion"),
        ("Routine aufbauen", "calendar"),
        ("Sonstige", "ellipsis")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            
            Image(systemName: step.systemImage)
                .font(.system(size: 60))
                .symbolRenderingMode(.hierarchical)
                .opacity(animate ? 1.0 : 0.0)
                .scaleEffect(animate ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
            
            Text(step.title)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.easeOut.delay(0.1), value: animate)
            
            Text(step.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.easeOut.delay(0.15), value: animate)
            
            VStack(spacing: 12) {
                ForEach(goals, id: \.title) { goal in
                    Button {
                        selectedGoal = goal.title
                        // Optional: hier könntest du das Ziel in @AppStorage speichern
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: goal.systemImage)
                                .font(.system(size: 22))
                            
                            Text(goal.title)
                                .font(.body)
                            
                            Spacer()
                            
                            if selectedGoal == goal.title {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedGoal == goal.title ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(animate ? 1.0 : 0.0)
                    .offset(y: animate ? 0 : 10)
                    .animation(.easeOut.delay(0.2), value: animate)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
        }
        .onAppear {
            animate = true
        }
    }
}

// Seite 3 – Features & „Loslegen“
struct OnboardingPageFeatures: View {
    let step: OnboardingStep
    let onFinish: () -> Void
    @State private var animate: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)
            
            Image(systemName: step.systemImage)
                .font(.system(size: 70))
                .symbolRenderingMode(.hierarchical)
                .opacity(animate ? 1.0 : 0.0)
                .scaleEffect(animate ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
            
            Text(step.title)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.easeOut.delay(0.1), value: animate)
            
            Text(step.subtitle)
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
                    title: "Logbuch",
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
            
            
            // Optional: eigener „Loslegen“-Button direkt auf der Seite
            Button(action: onFinish) {
                Text("Loslegen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
            }
            .opacity(animate ? 1.0 : 0.0)
            .animation(.easeOut.delay(0.25), value: animate)
            
            Spacer(minLength: 24)
        }
        .onAppear {
            animate = true
        }
    }
}

// Kleine Helper-View für Feature-Row
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

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
