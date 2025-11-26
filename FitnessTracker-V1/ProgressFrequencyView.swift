import SwiftUI
import Charts

struct ProgressFrequencyView: View {
    @EnvironmentObject var store: Store
    
    private let calendar = Calendar.current
    
    @State private var showInfo = false
    // MARK: - Period
    
    enum Period: String, CaseIterable, Identifiable {
        // Neue Reihenfolge für Links → Rechts: 4W, 3M, 6M, 12M
        case last4Weeks
        case last3Months
        case last6Months
        case last12Months
        
        var id: String { rawValue }
        
        /// Kurzes Label für den Segmented Picker
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
        
        /// Untertitel für die Gesamtanzahl
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
        let label: String     // z. B. "KW 47" oder "Jan"
        let start: Date
        let end: Date
        let count: Int
    }
    
    // MARK: - State
    
    @State private var selectedPeriod: Period = .last4Weeks
    @State private var selectedBucketLabel: String? = nil
    
    // MARK: - Formatter
    
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
            
            // MARK: - Apple-eigener Segmented Picker (Liquid Glass)
            Picker("", selection: $selectedPeriod) {
                ForEach(Period.allCases) { period in
                    Text(period.shortLabel)
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            // Ruhiger Info-Bereich
            metricRow(buckets: buckets)
            
            // Chart mit Tap-Selektion
            FrequencyChart(
                buckets: buckets,
                yUpper: yUpper,
                selectedBucketLabel: $selectedBucketLabel
            )
            
            Spacer()
        }
        .padding()
        .onChange(of: selectedPeriod) { _ in
            selectedBucketLabel = nil
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
                        Text("Hier siehst Du Deine Trainingsfrequenz in verschiedenen Zeitspannen.")
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
    
    // MARK: - Kennzahl-Zeile
    
    @ViewBuilder
    private func metricRow(buckets: [FrequencyBucket]) -> some View {
        let total = buckets.reduce(0) { $0 + $1.count }
        
        let selectedBucket = selectedBucketLabel.flatMap { label in
            buckets.first(where: { $0.label == label })
        }
        
        VStack(alignment: .leading, spacing: 2) {
            if let bucket = selectedBucket {
                Text("\(bucket.count) Trainings")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                
                switch selectedPeriod {
                case .last4Weeks:
                    Text("\(bucket.label)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                case .last3Months, .last6Months, .last12Months:
                    let monthString = monthDisplayFormatter.string(from: bucket.start)
                    Text("\(monthString)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("\(total) Trainings")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("\(selectedPeriod.metricSubtitle)")
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
    
    private func makeLast4WeeksBuckets() -> [FrequencyBucket] {
        var buckets: [FrequencyBucket] = []
        
        let now = Date()
        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        
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
    
    private func makeMonthlyBuckets(monthsBack: Int) -> [FrequencyBucket] {
        var buckets: [FrequencyBucket] = []
        
        let now = Date()
        guard let currentMonthInterval = calendar.dateInterval(of: .month, for: now) else {
            return []
        }
        
        let labelFormatter = DateFormatter()
        labelFormatter.locale = calendar.locale ?? Locale.current
        labelFormatter.dateFormat = "LLL"
        
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
            let endDate = calendar.date(byAdding: .day, value: -1, to: last.end) ?? last.end
            let endString = dateFormatter.string(from: endDate)
            return "\(selectedPeriod.displayTitle): \(startString) – \(endString)"
            
        case .last3Months, .last6Months, .last12Months:
            dateFormatter.dateFormat = "LLL yyyy"
            let startString = dateFormatter.string(from: first.start)
            let endString = dateFormatter.string(from: last.start)
            return "\(selectedPeriod.displayTitle): \(startString) – \(endString)"
        }
    }
}

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
        .chartXSelection(value: $selectedBucketLabel)
        .frame(height: 260)
    }
    
    private func color(for bucket: ProgressFrequencyView.FrequencyBucket) -> Color {
        guard let selected = selectedBucketLabel else { return .accentColor }
        return bucket.label == selected ? .accentColor : .secondary
    }
}

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
        
        var training = Training(title: "Ganzkörper")
        
        let recentDays: [Int] = [
            0, 2, 3,
            7, 9,
            14, 16,
            21, 23
        ]
        
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
