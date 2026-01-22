import SwiftUI

// MARK: - DashboardCard Component

struct DashboardCard: View {
    // MARK: Properties
    var title: String
    var amount: Double
    var icon: String? = nil
    var color: Color = .cyan
    var currency: String = "SGD"
    
    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                        .padding(8)
                        .background(color.opacity(0.1))
                        .clipShape(Circle())
                        .shadow(color: color.opacity(0.5), radius: 5, x: 0, y: 0) // Small neon glow
                }
            }
            
            Text(amount.formatted(.currency(code: currency)))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 0)
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.7))
                
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(colors: [color.opacity(0.5), color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: color.opacity(0.15), radius: 15, x: 0, y: 5) // Ambient glow
    }
}
