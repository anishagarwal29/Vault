import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Bindable var account: Account
    var balance: Double
    
    @State private var showingAddSheet = false
    @State private var editingSubscription: RecurringSubscription? // State for editing
    
    @Environment(\.dismiss) var dismiss
    
    // Derived properties
    var activeSubscriptionsCount: Int {
        account.subscriptions?.filter { $0.isActive }.count ?? 0
    }
    
    var estimatedMonthlyCost: Double {
        guard let subs = account.subscriptions else { return 0.0 }
        return subs.filter { $0.isActive }.reduce(0) { total, sub in
            var monthly: Double = 0
            if sub.billingUnit == "Month" {
                monthly = sub.amount / Double(sub.billingInterval)
            } else if sub.billingUnit == "Year" {
                monthly = sub.amount / (Double(sub.billingInterval) * 12)
            } else if sub.billingUnit == "Week" {
                monthly = sub.amount * 4 / Double(sub.billingInterval) // Approx
            }
            return total + monthly
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Traffic lights + Navigation)
                HStack {
                    // Custom Back Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Add Button
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Account Card Info
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue) // Or dynamic color
                                    .frame(width: 48, height: 48)
                                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: account.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(account.type.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(balance.formatted(.currency(code: "SGD")))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        
                        // Subscriptions Overview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Subscriptions Overview")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                StatCard(title: "Active Subscriptions", value: "\(activeSubscriptionsCount)")
                                StatCard(title: "Estimated Monthly Cost", value: estimatedMonthlyCost.formatted(.currency(code: "SGD")))
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        
                        // Subscriptions List Title
                        HStack {
                            Text("Subscriptions")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddSheet = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Subscriptions List / Empty State
                        if let subs = account.subscriptions, !subs.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(subs) { sub in
                                    SubscriptionRow(subscription: sub, onEdit: {
                                        editingSubscription = sub
                                    })
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Text("No subscriptions yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Add your first subscription to start tracking recurring charges for this account.")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                    .foregroundColor(Color.white.opacity(0.1))
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingAddSheet) {
            AddSubscriptionSheet(account: account)
                .presentationBackground(.clear)
        }
        .sheet(item: $editingSubscription) { sub in
            AddSubscriptionSheet(account: account, subscriptionToEdit: sub)
                .presentationBackground(.clear)
        }
    }
}

struct SubscriptionRow: View {
    let subscription: RecurringSubscription
    var onEdit: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var isHovering = false
    
    // Date Formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }

    var body: some View {
        HStack(alignment: .top) {
            // Left Side: Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(subscription.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if subscription.isFree {
                        Text("FREE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.3))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 8) {
                    if !subscription.isFree {
                        Text(subscription.amount.formatted(.currency(code: "SGD")))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    if subscription.isActive {
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green) // Green text for Active
                            .cornerRadius(4)
                    } else {
                         Text("Cancelled")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2)) // Red bg
                            .foregroundColor(.red) // Red text for Cancelled
                            .cornerRadius(4)
                    }
                }
                
                Text("Next billing: \(dateFormatter.string(from: subscription.nextPaymentDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !subscription.note.isEmpty {
                    Text(subscription.note)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Right Side: Billing Cycle & Actions
            HStack(spacing: 12) {
                if isHovering {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        modelContext.delete(subscription)
                    }) {
                         Image(systemName: "trash")
                           .font(.system(size: 12, weight: .bold))
                           .foregroundColor(.white)
                           .frame(width: 28, height: 28)
                           .background(Circle().fill(Color.red))
                    }
                    .buttonStyle(.plain)
                }
                
                Text(subscription.billingCycle) // e.g. "Every month"
                    .font(.caption) // Smaller
                    .foregroundColor(.secondary.opacity(0.7)) // More subtle
                    .padding(.top, 2) // Slight adjustment to align visually
            }
            .frame(height: 32)
        }
        .padding(16)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .background(Color(white: 0.1)) // Dark grey, not black
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1) // Subtle border for shape definition
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
