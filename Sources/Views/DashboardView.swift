import SwiftUI
import SwiftData

// MARK: - DashboardView

struct DashboardView: View {
    // MARK: Environment & Queries
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currency") private var currency: String = "SGD"
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Account.name) private var accounts: [Account]
    
    // MARK: State Properties
    @State private var editingTransaction: Transaction?
    
    // MARK: Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Cards Grid (Single Row)
                HStack(spacing: 16) {
                    DashboardCard(
                        title: "Expenses",
                        amount: totalExpenses,
                        icon: "arrow.up.right",
                        color: .red,
                        currency: currency
                    )
                    
                    DashboardCard(
                        title: "Income",
                        amount: totalIncome,
                        icon: "arrow.down.left",
                        color: .green,
                        currency: currency
                    )
                    
                    DashboardCard(
                        title: "Total Balance",
                        amount: totalBalance,
                        icon: "wallet.pass.fill",
                        color: .cyan, // Updated color for neon theme consistency
                        currency: currency
                    )
                }
                .padding(.horizontal)
                
                // Accounts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Accounts")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(accounts) { account in
                                NavigationLink(destination: AllTransactionsView(initialAccountFilter: account)) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: account.icon)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.blue.opacity(0.3))
                                                .clipShape(Circle())
                                            
                                            Spacer()
                                            
                                            Text(account.type.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(account.name)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            
                                            Text(calcBalance(for: account).formatted(.currency(code: currency)))
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(16)
                                    .frame(width: 160)
                                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recent Transactions
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Transactions")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    if allTransactions.isEmpty {
                        EmptyStateView()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(allTransactions.prefix(5)) { transaction in
                                TransactionRow(
                                    transaction: transaction,
                                    onEdit: {
                                        editingTransaction = transaction
                                    },
                                    onDelete: {
                                        deleteTransaction(transaction)
                                    }
                                )
                                .contextMenu {
                                     Button("Edit") { editingTransaction = transaction }
                                     Button("Delete", role: .destructive) { deleteTransaction(transaction) }
                                }
                                Divider()
                                    .opacity(0.5)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 80) // Space for floating button
            }
        }
        .sheet(item: $editingTransaction) { transaction in
            AddTransactionSheet(transactionToEdit: transaction)
        }
    }
    
    // MARK: Actions
    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
    }
    
    private func calcBalance(for account: Account) -> Double {
        let income = allTransactions
            .filter { $0.account?.id == account.id && $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expenses = allTransactions
            .filter { $0.account?.id == account.id && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
            
        let transfersOut = allTransactions
            .filter { $0.account?.id == account.id && $0.type == .transfer }
            .reduce(0) { $0 + $1.amount }
            
        let transfersIn = allTransactions
            .filter { $0.destinationAccount?.id == account.id && $0.type == .transfer }
            .reduce(0) { $0 + $1.amount }
            
        return income - expenses - transfersOut + transfersIn
    }
    
    // MARK: Computed Properties
    private var totalIncome: Double {
        allTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        allTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalBalance: Double {
        totalIncome - totalExpenses
    }
}

// MARK: - Empty State Component

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No transactions yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add your first transaction to get started.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
}
