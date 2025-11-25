import SwiftUI
import Charts

struct ProgressFrequencyView: View {
    @EnvironmentObject var store: Store
    
    private let calendar = Calendar.current
    
    // MARK: - Period
    
    enum Period: String, CaseIterable {
        case last12Months
        case last6Months
        case last3Months
        case last30Days
        
        /// Beschriftung im Selector
        var shortLabel: String {
            switch self {
            case .last12Months: return "12 M"
            case .last6Months:  return "6 M"
            case .last3Months:  return "3 M"
            case .last30Days:   return "30 T"
            }
        }
        
        /// Titel wie in der Health-App
        var displayTitle: String {
            switch self {
            case .last12Months: return "Letzte 12 Monate"
            case .last6Months:  return "Letzte 6 Monate"
            case .last3Months:  return "Letzte 3 Monate"
            case .last30Days:   return "Letzte 30 Tage"
            }
        }
        
        /// Untertitel für die Gesamtzahl
        var metricSubtitle: String {
            switch self {
            case .last12Months: return "in den letzten 12 Monaten"
            case .last6Months:  return "in den letzten 6 Monaten"
            case .last3Months:  return "in den letzten 3 Monaten"
            case .last30Days:   return "in den letzten 30 Tagen"
            }
        }
    }
    
    // MARK: - Datenmodell für den Chart
    
    struct FrequencyBucket: Identifiable {
        let id = UUID()
        let label: String     // z.B. "Jan" oder "24.11."
        let start: Date
        let end: Date
        let count: Int
    }
    
    // MARK: - State
    
    @State private var selectedPeriod: Period = .last30Days
    @State private var selectedBucketLabel: String? = nil
    
    // MARK: - Formatter (außerhalb von ViewBuilder!)
    
    private var dayDisplayFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = calendar.locale ?? Locale(identifier: "de_DE")
        df.dateFormat = "dd. MMM"
        return df
    }
    
    private var monthDisplayFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = calendar.locale ?? Locale(identifier: "de_DE")
        df.dateFormat = "MMMM yyyy"
        return df
    }
    
    // MARK: - Body
    
    var body: some View {
        let buckets = makeBuckets()
        let headerTitle = periodTitle(for: buckets)
        let maxCount = buckets.map { $0.count }.max() ?? 0
        let yUpper = max(1, maxCount)
        
        VStack(spacing: 16) {
            // Titel + Periode
            VStack(alignment: .leading, spacing: 4) {
                Text("Trainingsfrequenz")
                    .font(.title2.bold())
                Text(headerTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Health-ähnlicher Perioden-Selector
            periodSelector
            
            // Ruhiger Info-Bereich
            metricRow(buckets: buckets)
            
            // Chart
            FrequencyChart(
                buckets: buckets,
                yUpper: yUpper,
                selectedBucketLabel: $selectedBucketLabel
            )
            
            Spacer()
        }
        .padding()
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: selectedPeriod)
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(Period.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                    selectedBucketLabel = nil
                } label: {
                    Text(period.shortLabel)
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedPeriod == period ? Color.primary : Color.clear
                        )
                        .foregroundColor(
                            selectedPeriod == period
                            ? Color(UIColor.systemBackground)
                            : .primary
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    // MARK: - Kennzahl-Zeile
    
    @ViewBuilder
    private func metricRow(buckets: [FrequencyBucket]) -> some View {
        let total = buckets.reduce(0) { $0 + $1.count }
        
        let selectedBucket = selectedBucketLabel.flatMap { label in
            buckets.first(where: { $0.label == label })
        }
        
        VStack(alignment: .leading, spacing: 2) {
            if let bucket = selectedBucket {
                // Detailansicht für ausgewählten Balken
                Text("\(bucket.count)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                
                switch selectedPeriod {
                case .last30Days:
                    let dateString = dayDisplayFormatter.string(from: bucket.start)
                    Text("\(dateString) • Trainings an diesem Tag")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                case .last3Months, .last6Months, .last12Months:
                    let monthString = monthDisplayFormatter.string(from: bucket.start)
                    Text("\(monthString) • Trainings in diesem Monat")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else {
                // Gesamtansicht für die Periode
                Text("\(total)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Trainings \(selectedPeriod.metricSubtitle)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
    
    // MARK: - Daten
    
    private var allSessions: [WorkoutSession] {
        store.trainings.flatMap { $0.sessions }
    }
    
    private func makeBuckets() -> [FrequencyBucket] {
        switch selectedPeriod {
        case .last30Days:
            return makeLast30DaysBuckets()
        case .last3Months:
            return makeMonthlyBuckets(monthsBack: 3)
        case .last6Months:
            return makeMonthlyBuckets(monthsBack: 6)
        case .last12Months:
            return makeMonthlyBuckets(monthsBack: 12)
        }
    }
    
    /// Letzte 30 Tage: tägliche Buckets
    private func makeLast30DaysBuckets() -> [FrequencyBucket] {
        var buckets: [FrequencyBucket] = []
        
        let today = calendar.startOfDay(for: Date())
        
        let labelFormatter = DateFormatter()
        labelFormatter.locale = calendar.locale ?? Locale.current
        labelFormatter.dateFormat = "dd.MM."
        
        // Ältester Tag links, heute rechts
        for offset in stride(from: 29, through: 0, by: -1) {
            guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: today),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }
            
            let count = allSessions.filter { session in
                session.startedAt >= dayStart && session.startedAt < dayEnd
            }.count
            
            let label = labelFormatter.string(from: dayStart)
            
            buckets.append(
                FrequencyBucket(
                    label: label,
                    start: dayStart,
                    end: dayEnd,
                    count: count
                )
            )
        }
        
        return buckets
    }
    
    /// Letzte X Monate: monatliche Buckets (z. B. „Sep“, „Okt“, „Nov“)
    private func makeMonthlyBuckets(monthsBack: Int) -> [FrequencyBucket] {
        var buckets: [FrequencyBucket] = []
        
        let now = Date()
        guard let currentMonthInterval = calendar.dateInterval(of: .month, for: now) else {
            return []
        }
        
        let labelFormatter = DateFormatter()
        labelFormatter.locale = calendar.locale ?? Locale.current
        labelFormatter.dateFormat = "LLL"
        
        // Ältester Monat links, aktueller Monat rechts
        for offset in stride(from: monthsBack - 1, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentMonthInterval.start),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
                continue
            }
            
            let start = monthInterval.start
            let end = monthInterval.end
            
            let count = allSessions.filter { session in
                session.startedAt >= start && session.startedAt < end
            }.count
            
            let label = labelFormatter.string(from: start)
            
            buckets.append(
                FrequencyBucket(
                    label: label,
                    start: start,
                    end: end,
                    count: count
                )
            )
        }
        
        return buckets
    }
    
    // MARK: - Titel für die Periode (Health-Style)
    
    private func periodTitle(for buckets: [FrequencyBucket]) -> String {
        guard let first = buckets.first, let last = buckets.last else {
            return selectedPeriod.displayTitle
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = calendar.locale ?? Locale(identifier: "de_DE")
        
        switch selectedPeriod {
        case .last30Days:
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let startString = dateFormatter.string(from: first.start)
            let endString = dateFormatter.string(from: last.start)
            return "\(selectedPeriod.displayTitle) • \(startString) – \(endString)"
        case .last3Months, .last6Months, .last12Months:
            dateFormatter.dateFormat = "LLL yyyy"
            let startString = dateFormatter.string(from: first.start)
            let endString = dateFormatter.string(from: last.start)
            return "\(selectedPeriod.displayTitle) • \(startString) – \(endString)"
        }
    }
}

// MARK: - Nur Chart + Tap-Selektion

struct FrequencyChart: View {
    let buckets: [ProgressFrequencyView.FrequencyBucket]
    let yUpper: Int
    @Binding var selectedBucketLabel: String?
    
    var body: some View {
        Chart {
            ForEach(buckets) { bucket in
                BarMark(
                    x: .value("Periode", bucket.label),
                    y: .value("Workouts", bucket.count)
                )
                .foregroundStyle(color(for: bucket))
            }
        }
        .chartYScale(domain: 0...Double(yUpper))
        .chartXSelection(value: $selectedBucketLabel) // kurzer Tap, Auswahl bleibt
        .frame(height: 260)
    }
    
    private func color(for bucket: ProgressFrequencyView.FrequencyBucket) -> Color {
        guard let selected = selectedBucketLabel else { return .accentColor }
        return bucket.label == selected ? .accentColor : .secondary
    }
}

// MARK: - Preview

struct ProgressFrequencyView_Previews: PreviewProvider {
    static var previewStore: Store = {
        let store = Store()
        
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

// MARK: - Realistischer Preview mit Beispieldaten

struct ProgressFrequencyView_RealisticPreview: PreviewProvider {
    static var previewStore: Store = {
        let store = Store()
        let cal = Calendar.current
        let now = Date()
        
        func session(daysAgo: Int) -> WorkoutSession {
            let start = cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let end = cal.date(byAdding: .minute, value: 65, to: start) ?? start
            return WorkoutSession(
                startedAt: start,
                endedAt: end,
                maxWeightPerExercise: [:],
                exercises: []
            )
        }
        
        // Ein Workout mit vielen Sessions über 12 Monate verteilt
        var training = Training(title: "Ganzkörper")
        
        // Letzte 30 Tage (relativ dicht, inkl. ein paar Tage mit 2 Trainings)
        let recentDays: [Int] = [
            0,  // heute
            1, 1,  // zwei Trainings gestern
            3,
            5,
            7,
            9,
            11,
            13,
            15,
            18,
            20,
            23,
            26,
            29
        ]
        
        // Ältere Sessions für 3/6/12-Monats-Sicht
        let olderDays: [Int] = [
            35, 40, 47,      // vor ca. 1–2 Monaten
            60, 75, 90,      // 2–3 Monate
            120, 150, 180,   // 4–6 Monate
            210, 240, 270,   // 7–9 Monate
            300, 330         // 10–11 Monate
        ]
        
        let allDays = recentDays + olderDays
        
        training.sessions = allDays.map { session(daysAgo: $0) }
        
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
