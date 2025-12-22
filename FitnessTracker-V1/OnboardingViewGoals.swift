import SwiftUI

struct OnboardingViewGoals: View {
    @AppStorage("onboardingGoal") private var onboardingGoal: String = ""

    @State private var animate: Bool = false

    private let goals: [(title: String, systemImage: String)] = [
        ("Muskelaufbau", "dumbbell.fill"),
        ("Gewicht abnehmen", "arrow.down"),
        ("Kraft steigern", "bolt.circle"),
        ("Routine aufbauen", "calendar"),
        ("Überspringen", "")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 40)

                Image(systemName: "target")
                    .font(.system(size: 60))
                    .symbolRenderingMode(.hierarchical)
                    .opacity(animate ? 1.0 : 0.0)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)

                Text("Was ist Dein Ziel?")
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.1), value: animate)

                Text("Wähle das Ziel, welches am meisten auf Dich zutrifft – Du kannst es später jederzeit ändern.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.15), value: animate)

                VStack(spacing: 12) {
                    ForEach(goals, id: \.title) { goal in
                        Button {
                            onboardingGoal = goal.title
                        } label: {
                            HStack(spacing: 12) {
                                if !goal.systemImage.isEmpty {
                                    Image(systemName: goal.systemImage)
                                        .font(.system(size: 22))
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16))
                                        .opacity(0.0) // Platzhalter für Alignment
                                }

                                Text(goal.title)
                                    .font(.body)

                                Spacer()

                                if onboardingGoal == goal.title {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(onboardingGoal == goal.title
                                          ? Color.accentColor.opacity(0.15)
                                          : Color(.secondarySystemBackground))
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
}

struct OnboardingViewGoals_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingViewGoals()
    }
}
