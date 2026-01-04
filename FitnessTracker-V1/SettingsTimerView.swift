import SwiftUI

struct SettingsTimerView: View {
    @EnvironmentObject private var store: Store

    @State private var minutes: Int = 1
    @State private var seconds: Int = 30

    var body: some View {
        List {
            Section {
                Toggle("Pausentimer aktivieren", isOn: $store.restTimerEnabled)
                    .onChange(of: store.restTimerEnabled) { _, newValue in
                        print("⏱️ SettingsTimerView: restTimerEnabled -> \(newValue)")
                    }
            } footer: {
                Text("Wenn aktiv, kannst du im Workout einen Pausentimer starten. Nach Ablauf vibriert das iPhone und die Anzeige verschwindet.")
            }

            Section("Pausenlänge") {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dauer")
                        Text("\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Spacer()

                    HStack(spacing: 0) {
                        Picker("Minuten", selection: $minutes) {
                            ForEach(0...30, id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 110, height: 120)
                        .clipped()

                        Picker("Sekunden", selection: $seconds) {
                            ForEach(0...59, id: \.self) { s in
                                Text("\(s) s").tag(s)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 110, height: 120)
                        .clipped()
                    }
                }
                .disabled(!store.restTimerEnabled)
                .opacity(store.restTimerEnabled ? 1.0 : 0.45)
            }
        }
        .navigationTitle("Timer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let total = max(0, store.restTimerSeconds)
            minutes = total / 60
            seconds = total % 60
            print("⏱️ SettingsTimerView onAppear: loaded \(minutes)m \(seconds)s")
        }
        .onChange(of: minutes) { _, _ in persist() }
        .onChange(of: seconds) { _, _ in persist() }
    }

    private func persist() {
        let total = max(0, minutes * 60 + seconds)
        store.restTimerSeconds = total
        print("⏱️ SettingsTimerView: restTimerSeconds -> \(total)")
    }
}

#Preview {
    NavigationStack {
        SettingsTimerView()
            .environmentObject(Store())
    }
}
