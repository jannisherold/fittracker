import SwiftUI
import Charts

struct ProgressFrequencyView: View {
    @EnvironmentObject var store: Store
    
    private let calendar = Calendar.current
    
    enum Period: String, CaseIterable {
        case week
        case month
        case year
        
        var shortLabel: String {
            switch self {
            case .week: return "Woche"
            case .month: return "Monat"
            case .year: return "Jahr"
            }
        }
    }
    
    struct FrequencyBucket: Identifiable {
        let id = UUID()
        let label: String
        let start: Date
        let end: Date
        let count: Int
    }
    
    @State private var selectedPeriod: Period = .week
    /// 0 = aktuelle Periode, 1 = vorherige, usw.
    @State private var periodOffset: Int = 0
    
    /// Auswahl für Interaktivität: Label des gewählten Balkens
    @State private var selectedBucketLabel: String? = nil
    
    var body: some View {
        let buckets = makeBuckets()
        let headerTitle = periodTitle()
        let selectedCount = selectedBucketLabel.flatMap { label in
            buckets.first(where: { $0.label == label })?.count
        }
        let maxCount = buckets.map { $0.count }.max() ?? 0
        let yUpper = max(1, maxCount)
        
        VStack(spacing: 16) {
            // Titel + Periode (KW x / Monat / Jahr)
            VStack(alignment: .leading, spacing: 4) {
                Text("Trainingsfrequenz")
                    .font(.title2.bold())
                Text(headerTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Perioden-Buttons (Stocks-Style)
            periodSelector
            
            // Info zur aktuellen Selektion im Chart
            if let label = selectedBucketLabel, let count = selectedCount {
                Text("\(label): \(count) Trainings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Chart in Unter-View ausgelagert
            FrequencyChart(
                buckets: buckets,
                yUpper: yUpper,
                selectedBucketLabel: $selectedBucketLabel,
                periodOffset: $periodOffset
            )
            
            Spacer()
        }
        .padding()
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: selectedPeriod)
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: periodOffset)
    }
    
    // MARK: - Period Selector (Stocks-Style Buttons)
    
    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(Period.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                    periodOffset = 0
                    selectedBucketLabel = nil
                } label: {
                    Text(period.shortLabel)
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if selectedPeriod == period {
                                    Color.primary
                                } else {
                                    Color.clear
                                }
                            }
                        )
                        .foregroundColor(selectedPeriod == period ? Color(UIColor.systemBackground) : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    // MARK: - Datenaufbereitung
    
    /// Alle Sessions aus allen Trainings
    private var allSessions: [WorkoutSession] {
        store.trainings.flatMap { $0.sessions }
    }
    
    private func makeBuckets() -> [FrequencyBucket] {
        switch selectedPeriod {
        case .week:
            return makeWeekBuckets(offset: periodOffset)
        case .month:
            return makeMonthBuckets(offset: periodOffset)
        case .year:
            return makeYearBuckets(offset: periodOffset)
        }
    }
    
    // MARK: - Perioden-Intervalle + Titel
    
    private func weekInterval(offset: Int) -> DateInterval? {
        let now = Date()
        guard var start = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return nil }
        
        if offset > 0 {
            start = calendar.date(byAdding: .weekOfYear, value: -offset, to: start) ?? start
        }
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else { return nil }
        return DateInterval(start: start, end: end)
    }
    
    private func monthInterval(offset: Int) -> DateInterval? {
        let now = Date()
        guard var interval = calendar.dateInterval(of: .month, for: now) else { return nil }
        
        if offset > 0 {
            let refDate = calendar.date(byAdding: .month, value: -offset, to: interval.start) ?? interval.start
            interval = calendar.dateInterval(of: .month, for: refDate) ?? interval
        }
        return interval
    }
    
    private func yearInterval(offset: Int) -> DateInterval? {
        let now = Date()
        guard var interval = calendar.dateInterval(of: .year, for: now) else { return nil }
        
        if offset > 0 {
            let refDate = calendar.date(byAdding: .year, value: -offset, to: interval.start) ?? interval.start
            interval = calendar.dateInterval(of: .year, for: refDate) ?? interval
        }
        return interval
    }
    
    private func periodTitle() -> String {
        switch selectedPeriod {
        case .week:
            guard let interval = weekInterval(offset: periodOffset) else { return "" }
            let weekOfYear = calendar.component(.weekOfYear, from: interval.start)
            let year = calendar.component(.year, from: interval.start)
            return "KW \(weekOfYear), \(year)"
            
        case .month:
            guard let interval = monthInterval(offset: periodOffset) else { return "" }
            let formatter = DateFormatter()
            formatter.locale = calendar.locale ?? Locale(identifier: "de_DE")
            formatter.dateFormat = "LLLL yyyy" // z.B. August 2025
            return formatter.string(from: interval.start)
            
        case .year:
            guard let interval = yearInterval(offset: periodOffset) else { return "" }
            let year = calendar.component(.year, from: interval.start)
            return "\(year)"
        }
    }
    
    // MARK: Woche: 7 Tage (1 Feld = 1 Tag)
    
    private func makeWeekBuckets(offset: Int) -> [FrequencyBucket] {
        guard let weekInterval = weekInterval(offset: offset) else { return [] }
        let weekStart = weekInterval.start
        
        var buckets: [FrequencyBucket] = []
        
        let formatter = DateFormatter()
        formatter.locale = calendar.locale ?? Locale.current
        formatter.dateFormat = "E" // Mo, Di, Mi, ...
        
        for dayIndex in 0..<7 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayIndex, to: weekStart),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }
            
            let count = allSessions.filter { session in
                (session.startedAt >= dayStart && session.startedAt < dayEnd)
            }.count
            
            let label = formatter.string(from: dayStart)
            let bucket = FrequencyBucket(label: label, start: dayStart, end: dayEnd, count: count)
            buckets.append(bucket)
        }
        
        return buckets
    }
    
    // MARK: Monat: 4 Felder (jeweils ca. eine Woche)
    
    private func makeMonthBuckets(offset: Int) -> [FrequencyBucket] {
        guard let monthInterval = monthInterval(offset: offset) else { return [] }
        
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        var buckets: [FrequencyBucket] = []
        
        let weekLength: TimeInterval = 7 * 24 * 60 * 60
        
        for i in 0..<4 {
            let start = monthStart.addingTimeInterval(TimeInterval(i) * weekLength)
            let rawEnd = start.addingTimeInterval(weekLength)
            let end = min(rawEnd, monthEnd)
            
            let count = allSessions.filter { session in
                (session.startedAt >= start && session.startedAt < end)
            }.count
            
            let label = "W\(i + 1)"
            let bucket = FrequencyBucket(label: label, start: start, end: end, count: count)
            buckets.append(bucket)
        }
        
        return buckets
    }
    
    // MARK: Jahr: 12 Felder (1 Feld = 1 Monat)
    
    private func makeYearBuckets(offset: Int) -> [FrequencyBucket] {
        guard let yearInterval = yearInterval(offset: offset) else { return [] }
        let yearStart = yearInterval.start
        
        var buckets: [FrequencyBucket] = []
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = calendar.locale ?? Locale.current
        monthFormatter.dateFormat = "LLL" // Jan, Feb, ...
        
        for monthIndex in 0..<12 {
            guard let monthStart = calendar.date(byAdding: .month, value: monthIndex, to: yearStart),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
                continue
            }
            
            let start = monthInterval.start
            let end = monthInterval.end
            
            let count = allSessions.filter { session in
                (session.startedAt >= start && session.startedAt < end)
            }.count
            
            let label = monthFormatter.string(from: start)
            let bucket = FrequencyBucket(label: label, start: start, end: end, count: count)
            buckets.append(bucket)
        }
        
        return buckets
    }
}

// MARK: - Unter-View: kümmert sich nur um die Chart-Logik

struct FrequencyChart: View {
    let buckets: [ProgressFrequencyView.FrequencyBucket]
    let yUpper: Int
    @Binding var selectedBucketLabel: String?
    @Binding var periodOffset: Int
    
    var body: some View {
        Chart(buckets, id: \.id) { bucket in
            let isSelected = (selectedBucketLabel == bucket.label)
            let color: Color = {
                if selectedBucketLabel == nil {
                    return .accentColor
                } else {
                    return isSelected ? .accentColor : .secondary
                }
            }()
            
            BarMark(
                x: .value("Periode", bucket.label),
                y: .value("Workouts", bucket.count)
            )
            .foregroundStyle(color)
        }
        .chartYScale(domain: 0...Double(yUpper))
        .chartXSelection(value: $selectedBucketLabel) // eingebaute Selektion
        .frame(height: 260)
        .contentShape(Rectangle())
        // Swipe-Geste für Periode wechseln
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let threshold: CGFloat = 40
                    if value.translation.width < -threshold {
                        // Nach links swipen: eine Periode weiter in die Vergangenheit
                        periodOffset += 1
                        selectedBucketLabel = nil
                    } else if value.translation.width > threshold {
                        // Nach rechts swipen: zurück Richtung Gegenwart
                        periodOffset = max(periodOffset - 1, 0)
                        selectedBucketLabel = nil
                    }
                }
        )
    }
}

// MARK: - Preview mit Testdaten

struct ProgressFrequencyView_Previews: PreviewProvider {
    static var previewStore: Store = {
        let store = Store()
        
        // Für Preview: Beispiel-Daten
        var training = Training(title: "Push")
        let cal = Calendar.current
        let now = Date()
        
        func session(daysAgo: Int) -> WorkoutSession {
            let start = cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let end = cal.date(byAdding: .minute, value: 60, to: start) ?? start
            return WorkoutSession(
                startedAt: start,
                endedAt: end,
                maxWeightPerExercise: [:],
                exercises: []
            )
        }
        
        training.sessions = [
            session(daysAgo: 0),
            session(daysAgo: 1),
            session(daysAgo: 2),
            session(daysAgo: 5),
            session(daysAgo: 10),
            session(daysAgo: 20),
            session(daysAgo: 40),
            session(daysAgo: 80),
            session(daysAgo: 150),
            session(daysAgo: 250)
        ]
        
        store.trainings = [training]
        return store
    }()
    
    static var previews: some View {
        NavigationStack {
            ProgressFrequencyView()
                .environmentObject(previewStore)
        }
    }
}
