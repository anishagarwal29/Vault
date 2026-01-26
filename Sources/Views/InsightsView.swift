import SwiftUI
import SwiftData

struct InsightsView: View {
    @State private var selectedView: String = "Budget"
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Segmented Picker Header
                HStack {
                    Text("Insights")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Picker("", selection: $selectedView) {
                        Text("Budget").tag("Budget")
                        Text("Analytics").tag("Analytics")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Content
                if selectedView == "Budget" {
                    BudgetView()
                } else {
                    AnalyticsView()
                }
            }
        }
    }
}
