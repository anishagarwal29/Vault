import SwiftUI
import SwiftData
import Charts

// MARK: - AnalyticsView

struct AnalyticsView: View {
    // MARK: Queries & Environment
    @Query private var transactions: [Transaction]
    @AppStorage("currency") private var currency: String = "SGD"
    
    // MARK: State Properties
    @State private var timeRange: TimeRange = .month
    @State private var analyticsType: TransactionType = .expense
    @State private var hoveredCategory: String? = nil
    
    // MARK: Enums
    enum TimeRange: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        case all = "All Time"
    }
    
    // MARK: Computed Properties
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        return transactions.filter { t in
            guard t.type == analyticsType else { return false }
            
            switch timeRange {
            case .week:
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                return t.date >= weekStart
            case .month:
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return t.date >= monthStart
            case .year:
                let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!
                return t.date >= yearStart
            case .all:
                return true
            }
        }
    }
    
    var data: [(category: Category, amount: Double)] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.category }
        return grouped.compactMap { (key, value) in
            guard let category = key else { return nil }
            let total = value.reduce(0) { $0 + $1.amount }
            return (category, total)
        }.sorted { $0.amount > $1.amount }
    }
    
    var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: Body
    var body: some View {
        VStack(spacing: 24) {
            
                // Filter Control Bar
                VStack(spacing: 20) {
                    // Type Selector
                    Picker("", selection: $analyticsType) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    
                    // Time Range Selector
                    Picker("", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Content
                if data.isEmpty {
                    emptyStateView
                } else {
                    HStack(alignment: .center, spacing: 40) {
                        chartView
                        legendView
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 50)
        }
    
    // MARK: Subviews
    private var emptyStateView: some View {
        VStack {
            Spacer().frame(height: 50)
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.2))
                .shadow(color: .purple.opacity(0.2), radius: 20)
            
            Text("No data available")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var chartView: some View {
        ZStack {
            Chart(data, id: \.category.id) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.65),
                    angularInset: 2.0
                )
                .cornerRadius(6)
                .foregroundStyle(item.category.color)
                .opacity(hoveredCategory == nil || hoveredCategory == item.category.name ? 1.0 : 0.3)
                .shadow(radius: hoveredCategory == item.category.name ? 10 : 0) // Glow on hover
            }
            .chartLegend(.hidden)
            .frame(height: 320)
            
            // Center Text
            VStack {
                Text("Total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(totalAmount.formatted(.currency(code: currency)))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: 400)
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(data, id: \.category.id) { item in
                HStack {
                    Circle()
                        .fill(item.category.color)
                        .frame(width: 10, height: 10)
                        .shadow(color: item.category.color.opacity(0.8), radius: 4)
                    
                    Text(item.category.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.amount.formatted(.currency(code: currency)))
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text((item.amount / totalAmount).formatted(.percent.precision(.fractionLength(1))))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hoveredCategory == item.category.name ? Color.white.opacity(0.08) : Color.clear)
                )
                .scaleEffect(hoveredCategory == item.category.name ? 1.02 : 1.0)
                .onHover { isHovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveredCategory = isHovering ? item.category.name : nil
                    }
                }
            }
        }
        .frame(maxWidth: 300)
    }
}
