import SwiftUI
import SwiftData

struct AccountFilterView: View {
    @Query(sort: \Account.name) private var accounts: [Account]
    @Binding var selectedAccount: Account?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" Button
                FilterCapsule(
                    title: "All Accounts",
                    icon: "square.grid.2x2",
                    isSelected: selectedAccount == nil,
                    action: { selectedAccount = nil }
                )
                
                // Account Buttons
                ForEach(accounts) { account in
                    FilterCapsule(
                        title: account.name,
                        icon: account.icon,
                        isSelected: selectedAccount?.id == account.id,
                        action: { selectedAccount = account }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct FilterCapsule: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring, value: isSelected)
    }
}
