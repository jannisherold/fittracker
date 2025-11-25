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
        case last4Weeks
        
        /// Beschriftung im Selector
        var shortLabel: String {
            switch self {
            case .last12Months: return "12 M"
            case .last6Months:  return "6 M"
            case .last3Months:  return "3 M"
            case .last4Weeks:   return "4 W"
            }
        }
        
        /// Titel wie in der Health-App
        var displayTitle: String {
            switch self {
            case .last12Months: return "Letzte 12 Monate"
            case .last6Months:  return "Letzte 6 Monate"
            case .last3Months:  return "Letzte 3 Monate"
            case .last4Weeks:   return "Letzte 4 Wochen"
            }
        }
        
        /// Untertitel für die Gesamtzahl
        var metricSubtitle: String {
            switch self {
            case .last12Months: return "in den letzten 12 Monaten"
            case .last6Months:  return "in den letzten 6 Monaten"
            case .last3Months:  return "in den letzten 3 Monaten"
            case .last4Weeks:   return "in den letzten 4 Wochen"
            }
        }
    }
    
    // MARK: - Datenmodell für den Chart
    
    struct FrequencyBucket: Identifiable {
        let id = UUID()
        let label: String     // z.B. "KW 47" oder "Jan"
        let start: Date
        let end: Date
        let count: Int
    }
    
    // MARK: - State
    
    @State private var selectedPeriod: Period = .last4Weeks
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
                case .last4Weeks:
                    // label = "KW 47"
                    Text("\(bucket.label) • Trainings in dieser Woche")
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
        case .last4Weeks:
            return makeLast4WeeksBuckets()
        case .last3Months:
            return makeMonthlyBuckets(monthsBack: 3)
        case .last6Months:
            return makeMonthlyBuckets(monthsBack: 6)
        case .last12Months:
            return makeMonthlyBuckets(monthsBack: 12)
        }
    }
    
    /// Letzte 4 Wochen: wöchentliche Buckets (KW)
    private func makeLast4WeeksBuckets() -> [FrequencyBucket] {
        var buckets: [FrequencyBucket] = []
        
        let now = Date()
        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        
        // Älteste Woche links, aktuelle Woche rechts
        for offset in stride(from: 3, through: 0, by: -1) {
            guard let weekStart = calendar.date(
                byAdding: .weekOfYear,
                value: -offset,
                to: currentWeekInterval.start
            ),
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
                continue
            }
            
            let start = weekInterval.start
            let end = weekInterval.end
            
            let count = allSessions.filter { session in
                session.startedAt >= start && session.startedAt < end
            }.count
            
            let weekNumber = calendar.component(.weekOfYear, from: start)
            let label = "KW \(weekNumber)"
            
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
        case .last4Weeks:
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let startString = dateFormatter.string(from: first.start)
            // Ende = letzter Tag der letzten Woche
            let endDate = calendar.date(byAdding: .day, value: -1, to: last.end) ?? last.end
            let endString = dateFormatter.string(from: endDate)
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
        
        // Beispiel: viele Sessions über die letzten ~12 Monate
        var training = Training(title: "Ganzkörper")
        
        // Letzte 4 Wochen (ein paar Wochen mit mehreren Einheiten)
        let recentDays: [Int] = [
            0, 2, 3,  // aktuelle Woche
            7, 9,     // letzte Woche
            14, 16,   // vorletzte Woche
            21, 23    // dritte Woche zurück
        ]
        
        // Ältere Sessions für 3/6/12-Monats-Sichten
        let olderDays: [Int] = [
            35, 40, 47,
            60, 75, 90,
            120, 150, 180,
            210, 240, 270,
            300, 330
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
