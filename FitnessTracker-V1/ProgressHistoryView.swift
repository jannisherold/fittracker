import SwiftUI
import UIKit

struct ProgressHistoryView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    @State private var showInfo = false
    
    let trainingID: UUID
    let sessionID: UUID
    
    // Das zugehörige Training (für Titel u.ä.)
    private var training: Training {
        store.trainings.first(where: { $0.id == trainingID }) ?? Training(title: "Workout")
    }
    
    // Die ausgewählte Session (Zeitreise-Punkt)
    private var session: WorkoutSession? {
        training.sessions.first(where: { $0.id == sessionID })
    }
    
    private var hasExercises: Bool {
        if let session = session {
            return !session.exercises.isEmpty
        }
        return false
    }
    
    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()
            
            if let session = session, hasExercises {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Überschrift der ganzen Seite
                        VStack(spacing: 4) {
                            Text(training.title.uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 25)
                                .foregroundColor(.blue)
                            
                            // Datum + Dauer der konkreten Session
                            HStack(spacing: 6) {
                                Text(session.endedAt.formatted(date: .abbreviated, time: .omitted))
                                Text("-")
                                Text(formatDuration(session.duration))
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 25)
                        }
                        
                        // Übungs-Karten – jetzt aus der Session-Snapshot-Struktur
                        ForEach(session.exercises) { ex in
                            VStack(alignment: .leading, spacing: 5) {
                                
                                Text(ex.name)
                                    .font(.title2.weight(.bold))
                                    .padding(.horizontal, 30)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(Array(ex.sets.enumerated()), id: \.element.id) { idx, set in
                                        
                                        if idx > 0 {
                                            Divider().padding(.horizontal, 16)
                                        }
                                        
                                        VStack {
                                            Text("\(idx + 1). Satz")
                                                .fontWeight(.regular)
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 14))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            HStack {
                                                Image(systemName: "scalemass.fill")
                                                    .foregroundColor(.secondary)
                                                
                                                Text("\(formatWeight(set.weightKg)) kg")
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                
                                                Image(systemName: "repeat")
                                                    .foregroundColor(.secondary)
                                                
                                                Text("\(set.repetition.value) Wdh.")
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 2)
                        }
                        
                        Spacer(minLength: 80)
                    }
                }
                .scrollIndicators(.never)
                
            } else {
                // Fallback, falls für alte Sessions noch keine Snapshots vorliegen
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Für diese Session liegen keine detaillierten Trainingsdaten vor.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Zurück")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Der Button zeigt/versteckt ein *normales SwiftUI*-Popover.
                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "info")
                }
                .accessibilityLabel("Info")
                // Das Popover ist direkt am Button verankert, kompakt und inhaltsbasiert.
                .popover(isPresented: $showInfo,
                         attachmentAnchor: .point(.topTrailing),
                         arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hier findest Du alle Details zu diesem Workout-Tag.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }
                    .padding(16)
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
                    .presentationSizing(.fitted)               // nur so groß wie der Inhalt
                    .presentationCompactAdaptation(.popover)   // iPhone bleibt Popover (kein Sheet)
                }
            }
        }
    }
    
    // MARK: - Gewicht formatieren (wie in WorkoutRunView)
    private func formatWeight(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 3
        nf.decimalSeparator = ","
        return nf.string(from: NSNumber(value: value)) ?? String(value).replacingOccurrences(of: ".", with: ",")
    }
    
    // MARK: - Dauer formatieren (z.B. "1 h 12 min" oder "45 min")
    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours) h \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}
