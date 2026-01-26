import SwiftUI
import SwiftData

// MARK: - AllTransactionsView

struct AllTransactionsView: View {
    // MARK: Environment
    @Environment(\.modelContext) private var modelContext
    
    // MARK: Queries
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Account.name) private var accounts: [Account]
    
    var initialAccountFilter: Account?
    
    // MARK: State Properties
    @State private var searchText = ""
    @State private var selectedTypeFilter: TransactionType? = nil
    @State private var selectedAccountFilter: Account? = nil
    @State private var hoverEditId: UUID? = nil
    @State private var editingTransaction: Transaction? = nil


    // MARK: Computed Properties
    /// Filters transactions based on search text, selected type, and selected account
    var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            let matchesSearch = searchText.isEmpty || 
                (transaction.note.localizedCaseInsensitiveContains(searchText) ||
                 (transaction.category?.name.localizedCaseInsensitiveContains(searchText) ?? false))
            
            let matchesType = selectedTypeFilter == nil || transaction.type == selectedTypeFilter
            
            // Matches if the account is the source OR the destination (for transfers)
            let matchesAccount = selectedAccountFilter == nil || 
                                 transaction.account?.id == selectedAccountFilter?.id ||
                                 transaction.destinationAccount?.id == selectedAccountFilter?.id
            
            return matchesSearch && matchesType && matchesAccount
        }
    }
    
    // MARK: Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top Bar
                VStack(spacing: 16) {
                    HStack {
                        Text("Transactions")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search transactions...", text: $searchText)
                                .textFieldStyle(.plain)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Filter
                        Menu {
                            Button(action: { selectedTypeFilter = nil }) {
                                Label("All", systemImage: "line.3.horizontal.circle")
                            }
                            Button(action: { selectedTypeFilter = .income }) {
                                Label("Income", systemImage: "arrow.down.left")
                            }
                            Button(action: { selectedTypeFilter = .expense }) {
                                Label("Expense", systemImage: "arrow.up.right")
                            }
                            Button(action: { selectedTypeFilter = .transfer }) {
                                Label("Transfer", systemImage: "arrow.right.arrow.left")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 32)
                    }
                    
                    // Account Filter
                    AccountFilterView(selectedAccount: $selectedAccountFilter)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Transactions List
                if filteredTransactions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No transactions found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTransactions) { transaction in
                            TransactionRow(transaction: transaction, onEdit: {
                                editingTransaction = transaction
                            }, onDelete: {
                                deleteTransaction(transaction)
                            })
                            .contextMenu {
                                Button("Edit") { editingTransaction = transaction }
                                Button("Delete", role: .destructive) { deleteTransaction(transaction) }
                            }
                            
                            if transaction.id != filteredTransactions.last?.id {
                                Divider().opacity(0.1)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 80) // Space for floating button
        }
        .sheet(item: $editingTransaction) { transaction in
            AddTransactionSheet(transactionToEdit: transaction)
        }

        .onAppear {
            if let account = initialAccountFilter {
                selectedAccountFilter = account
            }
        }
    }
    
    // MARK: Actions
    
    private func deleteTransaction(_ transaction: Transaction) {
        withAnimation {
            modelContext.delete(transaction)
        }
    }
    

}
