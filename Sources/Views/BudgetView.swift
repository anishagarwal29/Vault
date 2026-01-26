import SwiftUI
import SwiftData

/// The main view for displaying and managing users' budgets.
/// It creates a visual representation of budget limits and goals vs actual spending/income.
struct BudgetView: View {
    // MARK: - Persistent Data
    
    // Fetch all budgets, sorted by creation date (newest first)
    @Query(sort: \Budget.dateCreated, order: .reverse) private var budgets: [Budget]
    
    // Fetch all transactions to calculate current spending against budgets
    @Query private var transactions: [Transaction]
    
    // Fetch accounts to populate the filter dropdown
    @Query(sort: \Account.name) private var accounts: [Account]
    
    // MARK: - State & AppStorage
    
    // The user's preferred currency symbol
    @AppStorage("currency") private var currency: String = "SGD"
    
    // Filter state: If nil, show all budgets. If set, show only budgets for that account (or global ones).
    @State private var selectedAccountFilter: Account? = nil
    
    // MARK: - Computed Properties
    
    /// Filters the fetched budgets based on the `selectedAccountFilter`.
    /// - Returns: A list of budgets that match the selected account or are global (account == nil).
    var filteredBudgets: [Budget] {
        if let account = selectedAccountFilter {
            return budgets.filter { budget in
                // Show Global Category Budgets (account == nil)
                // OR Specific Account Budget for this account
                return budget.account == nil || budget.account?.id == account.id
            }
        } else {
            return budgets
        }
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Account Filter Bar
                // A horizontal bar allowing the user to switch between accounts or view all.
                VStack(spacing: 0) {
                    AccountFilterView(selectedAccount: $selectedAccountFilter)
                        .padding(.vertical, 10)
                }
                .zIndex(1) // Ensures it stays above scrolling content if creating overlap effects

                // MARK: Main Content Area
                VStack(spacing: 24) {
                    // Empty State
                    if filteredBudgets.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                                
                            Text("No Budgets Found")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            if selectedAccountFilter != nil {
                                 Text("No budgets linked to this account.")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Go to Settings to set monthly budgets for Categories or Accounts.")
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                        .padding()
                    } else {
                        // Budget List
                        // Uses LazyVStack for performance optimization with many items
                        LazyVStack(spacing: 20) {
                            ForEach(filteredBudgets) { budget in
                                BudgetCard(
                                    budget: budget, 
                                    transactions: transactions, 
                                    currency: currency,
                                    filterAccount: selectedAccountFilter
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
                .padding(.top, 20)
            }
        }
        .onAppear {
            // Automatically select the first account if no filter is set on first load.
            // This ensures the user sees a specific context (Main account) rather than "All" by default.
            if selectedAccountFilter == nil, let firstAccount = accounts.first {
                selectedAccountFilter = firstAccount
            }
        }
    }
}

/// A card component displaying a single budget's status.
/// It calculates progress based on transactions and shows a progress bar.
struct BudgetCard: View {
    // MARK: - Properties
    let budget: Budget
    let transactions: [Transaction]
    let currency: String
    var filterAccount: Account? = nil 
    
    // MARK: - Computed Helpers

    /// Determines if this is an Income Goal (Green is good) or Expense Limit (Red is bad).
    var isIncomeBudget: Bool {
        if let cat = budget.category {
            return cat.type == .income
        }
        return false // Account budgets are implicitly spending limits for now
    }

    /// Selects the icon based on category or account.
    var icon: String {
        if let cat = budget.category { return cat.icon }
        if let acc = budget.account { return acc.icon }
        return "dollarsign.circle"
    }
    
    /// Selects the color based on category.
    var color: Color {
        if let cat = budget.category { return cat.color }
        return .blue
    }
    
    /// Formats the display name of the budget.
    /// Handles partial context (e.g. showing Account name if viewing All Budgets).
    var name: String {
        if let cat = budget.category {
            // If viewing specific account budget in "All" mode, clarify the account name
            if filterAccount == nil, let acc = budget.account {
                return "\(cat.name) (\(acc.name))"
            }
            return cat.name
        } else if let acc = budget.account {
             // Account-wide limit
            if filterAccount == nil {
                return "\(acc.name) Limit"
            } else {
                return "Monthly Spending Limit"
            }
        }
        return "Budget"
    }

    /// Calculates the total amount spent (or earned) towards this budget in the current month.
    var currentAmount: Double {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components) else { return 0 }
        
        return transactions.filter { t in
            // 1. Date Check: Only current month
            guard t.date >= startOfMonth else { return false }
            
            // 2. Type Check: Match budget type
            if isIncomeBudget {
                guard t.type == .income else { return false }
            } else {
                guard t.type == .expense else { return false }
            }
            
            // 3. Filter Context Check: If visual filter is active, only count transactions for that account
            if let filterAcc = filterAccount {
                guard t.account?.id == filterAcc.id else { return false }
            }
            
            // 4. Budget Match Logic
            // - Specific Category & Account Budget
            if let cat = budget.category, let acc = budget.account {
                return t.category?.id == cat.id && t.account?.id == acc.id
            } 
            // - Global Category Budget
            else if let cat = budget.category {
                return t.category?.id == cat.id
            } 
            // - Account Limit Budget
            else if let acc = budget.account {
                return t.account?.id == acc.id
            }
            return false
        }
        .reduce(0) { $0 + $1.amount }
    }

    /// The budget target amount.
    var limit: Double {
        budget.amount
    }

    /// Progress ratio (0.0 to 1.0).
    var progress: Double {
        guard limit > 0 else { return 0 }
        return min(currentAmount / limit, 1.0)
    }

    /// Determines the color of the progress bar based on status.
    var progressColor: Color {
        if isIncomeBudget {
            // Income High = Good
            if currentAmount >= limit { return .green }
            return .blue // In progress
        } else {
            // Expense High = Bad
            if currentAmount > limit { return .red }
            if progress > 0.8 { return .orange }
            return .green
        }
    }

    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            // Header Row: Icon, Name, Amounts
            HStack {
               // Icon and Name
               HStack(spacing: 12) {
                   Image(systemName: icon)
                       .foregroundColor(color)
                       .font(.title3)
                       .frame(width: 30)
                   
                   VStack(alignment: .leading, spacing: 2) {
                       Text(name)
                           .font(.headline)
                       if isIncomeBudget {
                           Text("Monthly Goal")
                               .font(.caption2)
                               .foregroundColor(.secondary)
                               .textCase(.uppercase)
                       }
                   }
               }

               Spacer()

               // Amount Text (Current / Total)
               VStack(alignment: .trailing) {
                   Text("\(currency) \(String(format: "%.0f", currentAmount)) / \(String(format: "%.0f", limit))")
                       .font(.subheadline)
                       .fontWeight(.medium)
                   
                   Text("\(String(format: "%.0f", (currentAmount/limit)*100))%")
                       .font(.caption)
                       .foregroundColor(.secondary)
               }
            }

            // Progress Bar (Visual Indicator)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 12)

                    // Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 12)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 12)

            // Footer / Message Row
            if isIncomeBudget {
                if currentAmount >= limit {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Goal reached! Extra: \(currency) \(String(format: "%.0f", currentAmount - limit))")
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                     Text("\(currency) \(String(format: "%.0f", limit - currentAmount)) to go")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                if currentAmount > limit {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Over budget by \(currency) \(String(format: "%.0f", currentAmount - limit))")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                     Text("\(currency) \(String(format: "%.0f", limit - currentAmount)) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        // Glassmorphism-style card background
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
