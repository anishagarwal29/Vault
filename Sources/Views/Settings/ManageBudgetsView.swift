import SwiftUI
import SwiftData

/// View for managing global and specific budgets.
/// Allows adding, editing, and deleting budgets.
struct ManageBudgetsView: View {
    // MARK: - Environment & Data
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Fetch budgets sorted by creation date (newest first) to maintain context when adding.
    @Query(sort: \Budget.dateCreated, order: .reverse) private var budgets: [Budget]
    
    // MARK: - State
    
    @State private var showingAddSheet = false
    @State private var budgetToEdit: Budget?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            HStack {
                Text("Budgets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            // MARK: Budget List
            if budgets.isEmpty {
                // Empty State
                Spacer()
                ContentUnavailableView("No Budgets", systemImage: "chart.pie", description: Text("Create a budget to track your spending."))
                Spacer()
            } else {
                // Using Query directly updates the list. 
                // We use ScrollViewReader to programmatically scroll to the top when a new item is added.
                ScrollViewReader { proxy in
                    List {
                        ForEach(budgets) { budget in
                            BudgetRowView(
                                budget: budget,
                                onEdit: { budgetToEdit = budget },
                                onDelete: { modelContext.delete(budget) }
                            )
                            .id(budget.id) // Ensure ID is explicit for scrolling
                        }
                        .onDelete(perform: deleteBudgets)
                    }
                    .scrollContentBackground(.hidden)
                    .onChange(of: budgets.count) { _, _ in
                        // Scroll to the first item (newest) when a new budget is added
                        if let firstID = budgets.first?.id {
                            withAnimation {
                                proxy.scrollTo(firstID, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            BudgetFormView()
        }
        .sheet(item: $budgetToEdit) { budget in
            BudgetFormView(budgetToEdit: budget)
        }
    }
    
    // MARK: - Actions
    
    private func deleteBudgets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(budgets[index])
        }
    }
}

/// A row view displaying summary information for a single budget in the management list.
struct BudgetRowView: View {
    // MARK: - Properties
    
    let budget: Budget
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon Configuration
            Group {
                if let cat = budget.category {
                    Image(systemName: cat.icon)
                        .foregroundColor(cat.color)
                } else if let acc = budget.account {
                    Image(systemName: acc.icon)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.secondary)
                }
            }
            .font(.title3)
            .frame(width: 32)
            
            // Name & Context
            VStack(alignment: .leading, spacing: 2) {
                if let cat = budget.category {
                    Text(cat.name).fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(budget.account != nil ? "Category Budget (\(budget.account!.name))" : "Global Category Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let acc = budget.account {
                    Text(acc.name).fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("Account Limit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Unassigned Budget").fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Actions (Edit/Delete) - visible on hover
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red.opacity(0.9))
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 64)
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
            
            // Amount
            Text(String(format: "$%.0f", budget.amount))
                .font(.body)
                .monospacedDigit()
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? Color.primary.opacity(0.04) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button("Edit") { onEdit() }
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

/// Form for creating or editing a budget object.
struct BudgetFormView: View {
    // MARK: - Environment & Data
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var budgetToEdit: Budget?
    
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Account.name) private var accounts: [Account]
    
    // MARK: - Form State
    
    @State private var amountString = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Text(budgetToEdit == nil ? "New Budget" : "Edit Budget")
                .font(.headline)
            
            // Amount Input
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCategory?.type == .income ? "Monthly Goal" : "Monthly Limit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Amount", text: $amountString)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Pickers
            VStack(spacing: 16) {
                // Category Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as Category?)
                        
                        Divider()
                        
                        Section("Expense") {
                            ForEach(categories.filter { $0.type == .expense }) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.name)
                                }
                                .tag(cat as Category?)
                            }
                        }
                        
                        Section("Income") {
                            ForEach(categories.filter { $0.type == .income }) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.name)
                                }
                                .tag(cat as Category?)
                            }
                        }
                    }
                    .labelsHidden()
                }
                
                // Account Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $selectedAccount) {
                        Text("All Accounts").tag(nil as Account?)
                        ForEach(accounts) { acc in
                            HStack {
                                Image(systemName: acc.icon)
                                Text(acc.name)
                            }
                            .tag(acc as Account?)
                        }
                    }
                    .labelsHidden()
                }
            }
            
            // Helper Text to explain the budget type based on selection
            if let cat = selectedCategory {
                if cat.type == .income {
                    if let acc = selectedAccount {
                        Text("Income goal for \(cat.name) into \(acc.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Global income goal for \(cat.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    if let acc = selectedAccount {
                        Text("Budget for \(cat.name) using \(acc.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Global budget for \(cat.name) across all accounts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if let acc = selectedAccount {
                Text("Total spending limit for \(acc.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(amountString.isEmpty || (selectedCategory == nil && selectedAccount == nil))
            }
        }
        .padding()
        .frame(width: 350, height: 400)
        .onAppear {
            if let budget = budgetToEdit {
                // Populate form for editing
                amountString = String(format: "%.0f", budget.amount)
                selectedCategory = budget.category
                selectedAccount = budget.account
            } else {
                // Auto-select first account for new budgets for better UX
                 if selectedAccount == nil, let first = accounts.first {
                    selectedAccount = first
                 }
            }
        }
    }
    
    // MARK: - Save Handler
    
    private func save() {
        let finalAmount = Double(amountString) ?? 0
        
        if let budget = budgetToEdit {
            budget.amount = finalAmount
            budget.category = selectedCategory
            budget.account = selectedAccount
            // Note: We don't update dateCreated on edit to preserve order
        } else {
            let newBudget = Budget(
                amount: finalAmount,
                account: selectedAccount,
                category: selectedCategory
            )
            modelContext.insert(newBudget)
        }
        dismiss()
    }
}
