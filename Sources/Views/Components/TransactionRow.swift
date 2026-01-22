import SwiftUI

// MARK: - TransactionRow Component

struct TransactionRow: View {
    // MARK: Properties
    let transaction: Transaction
    var onHover: ((Bool) -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    // MARK: State Properties
    @State private var isHovering = false
    
    // MARK: Body
    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                    .shadow(color: iconColor.opacity(0.3), radius: 5)
                
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.system(size: 16, weight: .semibold)) // Slightly bolder
                    .foregroundColor(.primary)
                
                // "Date Month Year" format -> 12 Jan 2026 or 12 January 2026. 
                // .dateTime.day().month(.wide).year() gives "January 12, 2026" (US) or "12 January 2026" (UK/others).
                // To force order, we can format manually or trust standard long format which usually includes these fields appropriately.
                // User asked for "date month year", which usually implies order DD MM YYYY.
                if transaction.subscription != nil {
                    Text("Subscription • \(transaction.date.formatted(Date.FormatStyle().year().month(.wide).day().locale(Locale(identifier: "en_GB"))))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(transaction.date.formatted(Date.FormatStyle().year().month(.wide).day().locale(Locale(identifier: "en_GB"))))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            HStack(alignment: .center, spacing: 16) {
                
                // Actions (Edit/Delete) - Fixed Width Container
                // We use opacity to hide/show so it doesn't shift layout
                HStack(spacing: 8) {
                    if isHovering {
                        Button(action: { onEdit?() }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                        
                        Button(action: { onDelete?() }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .frame(width: 60, alignment: .trailing) // Reserve space for buttons
                
                // Account Info & Amount Group
                HStack(spacing: 8) {
                    if transaction.type == .transfer {
                        HStack(spacing: 2) {
                            if let from = transaction.account {
                                Image(systemName: from.icon)
                                    .foregroundColor(.secondary)
                                    .help("From: \(from.name)")
                            }
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let to = transaction.destinationAccount {
                                Image(systemName: to.icon)
                                    .foregroundColor(.secondary)
                                    .help("To: \(to.name)")
                            }
                        }
                    } else {
                        if let account = transaction.account {
                            HStack(spacing: 4) {
                                Image(systemName: account.icon)
                                Text(account.name)
                            }
                            .foregroundColor(.secondary)
                            .font(.caption)
                        }
                    }
                    
                    Text(amountString)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(amountColor)
                        .shadow(color: shadowColor.opacity(0.6), radius: 8)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                // Deeper background
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        )
        // Neon Glow Border based on type
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            strokeColor.opacity(isHovering ? 0.6 : 0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
            onHover?(hovering)
        }
        .contentShape(Rectangle())
    }
    
    // MARK: - Helpers
    
    private var iconName: String {
        if transaction.type == .transfer {
            return "arrow.right.arrow.left"
        } else {
            return transaction.category?.icon ?? "questionmark"
        }
    }
    
    private var iconColor: Color {
        if transaction.type == .transfer {
            return .blue
        } else {
            return transaction.category?.color ?? .gray
        }
    }
    
    private var titleText: String {
        if let subscription = transaction.subscription {
            return subscription.name
        } else if transaction.type == .transfer {
            return "Transfer"
        } else {
            return transaction.category?.name ?? "Uncategorized"
        }
    }
    
    private var amountString: String {
        let prefix: String
        switch transaction.type {
        case .income: prefix = "+ "
        case .expense: prefix = "- "
        case .transfer: prefix = ""
        }
        return prefix + transaction.amount.formatted(.currency(code: transaction.currency))
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .white
        case .transfer: return .blue
        }
    }
    
    private var shadowColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .pink
        case .transfer: return .blue
        }
    }
    
    private var strokeColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
}
