import SwiftUI
import SwiftData
import PhotosUI

// MARK: - AddTransactionSheet

struct AddTransactionSheet: View {
    // MARK: Environment & Queries
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Account.name) private var accounts: [Account]
    
    @AppStorage("currency") private var currency: String = "SGD"
    
    // MARK: State Properties
    @State private var type: TransactionType = .expense
    @State private var amount: Double = 0.0
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var selectedDestinationAccount: Account? // For transfers
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var transactionCurrency: String = "SGD"
    
    // MARK: UI State
    @State private var isHoveringClose = false
    @State private var isHoveringSave = false
    @State private var showingAddAccountSheet = false
    
    var transactionToEdit: Transaction? = nil
    
    // MARK: Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(spacing: 35) {
                    amountInputView
                    mainFormView
                    saveButtonView
                }
                .padding(.horizontal, 40)
            }
        }
        .frame(width: 500, height: 750)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
        .onAppear {
            if let transaction = transactionToEdit {
                // Load existing data
                type = transaction.type
                amount = transaction.amount
                date = transaction.date
                note = transaction.note
                selectedCategory = transaction.category
                selectedAccount = transaction.account
                selectedDestinationAccount = transaction.destinationAccount
                selectedImageData = transaction.imageData
                transactionCurrency = transaction.currency
            } else {
                // Defaults for new transaction
                if selectedCategory == nil {
                    selectedCategory = categories.first(where: { $0.type == type })
                }
                if selectedAccount == nil {
                    selectedAccount = accounts.first
                }
                // Use global preference for new
                transactionCurrency = currency
            }
        }
        .onChange(of: type) { _, newType in
            if transactionToEdit == nil {
                if newType != .transfer {
                    selectedCategory = categories.first(where: { $0.type == newType })
                } else {
                    selectedCategory = nil
                }
            }
        }
        .sheet(isPresented: $showingAddAccountSheet) {
            AccountFormView()
        }
    }
    
    // MARK: - Subviews
    
    /// Header with close button and type selector/title
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
                .padding(10)
                .background(Color.white.opacity(isHoveringClose ? 0.1 : 0.05))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .onHover { isHoveringClose = $0 }
            
            Spacer()
            
            if transactionToEdit == nil {
                Picker("Type", selection: $type) {
                    Text("Expense").tag(TransactionType.expense)
                    Text("Income").tag(TransactionType.income)
                    Text("Transfer").tag(TransactionType.transfer)
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                .labelsHidden()
            } else {
                Text("Edit Transaction")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Balance out the close button for centering
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(16)
    }
    
    
    // MARK: Actions
    
    private func saveTransaction() {
        let account = selectedAccount ?? accounts.first
        
        if let transaction = transactionToEdit {
            // Update existing
            transaction.amount = amount
            transaction.date = date
            transaction.note = note
            transaction.type = type
            transaction.category = (type == .transfer) ? nil : selectedCategory
            transaction.account = account
            transaction.destinationAccount = (type == .transfer) ? selectedDestinationAccount : nil
            transaction.imageData = selectedImageData
            transaction.currency = transactionCurrency
        } else {
            // Insert new
            let newTransaction = Transaction(
                amount: amount,
                date: date,
                note: note,
                type: type,
                category: (type == .transfer) ? nil : selectedCategory,
                account: account,
                destinationAccount: (type == .transfer) ? selectedDestinationAccount : nil,
                imageData: selectedImageData,
                currency: transactionCurrency
            )
            modelContext.insert(newTransaction)
        }
        dismiss()
    }
    
    private var saveButtonView: some View {
        let isValid: Bool = {
            if amount == 0 { return false }
            if type == .transfer {
                return selectedAccount != nil && selectedDestinationAccount != nil && selectedAccount?.id != selectedDestinationAccount?.id
            } else {
                return selectedCategory != nil
            }
        }()
        
        return Button(action: saveTransaction) {
            Text(transactionToEdit == nil ? "Save Transaction" : "Update Transaction")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: gradientColors.first?.opacity(0.4) ?? .clear, radius: 10, y: 5)
                )
                .scaleEffect(isHoveringSave ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHoveringSave = $0 }
        .padding(.bottom, 30)
        .animation(.spring(response: 0.3), value: isHoveringSave)
        .disabled(!isValid)
        .opacity(isValid ? 1 : 0.5)
    }
    
    private var gradientColors: [Color] {
        switch type {
        case .income: return [.green, .mint]
        case .expense: return [Color.pink, Color.purple]
        case .transfer: return [.blue, .cyan]
        }
    }

    private var amountInputView: some View {
        VStack(spacing: 10) {            
            HStack(spacing: 20) {
                Text(transactionCurrency)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                
                TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .shadow(color: gradientColors.last?.opacity(0.3) ?? .clear, radius: 10)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 20)
    }
    
    private var mainFormView: some View {
        VStack(spacing: 20) {
            if type != .transfer {
                categoryPickerView
                Divider().opacity(0.3)
            }
            
            datePickerView
            Divider().opacity(0.3)
            
            accountPickerView(
                title: type == .transfer ? "From Account" : "Account",
                selection: $selectedAccount,
                items: accounts
            )
            
            if type == .transfer {
                Divider().opacity(0.3)
                accountPickerView(
                    title: "To Account",
                    selection: $selectedDestinationAccount,
                    items: accounts.filter { $0.id != selectedAccount?.id }
                )
            }
            
            Divider().opacity(0.3)
            notesInputView
            Divider().opacity(0.3)
            receiptPickerView
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.spring, value: type)
    }

    private var categoryPickerView: some View {
        HStack {
            Label("Category", systemImage: "tag.fill")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Menu {
                let filtered = categories.filter { $0.type == type }
                if filtered.isEmpty {
                    Text("No categories found")
                } else {
                    ForEach(filtered) { category in
                        Button(action: { selectedCategory = category }) {
                            Label(category.name, systemImage: category.icon)
                        }
                    }
                }
            } label: {
                HStack {
                    if let cat = selectedCategory {
                        Image(systemName: cat.icon)
                            .foregroundColor(cat.color)
                        Text(cat.name)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    } else {
                        Text("Select Category")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(width: 200)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
    }

    private var datePickerView: some View {
        HStack {
            Label("Date", systemImage: "calendar")
                .foregroundColor(.secondary)
            Spacer()
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .colorMultiply(.accentColor)
        }
    }

    private func accountPickerView(title: String, selection: Binding<Account?>, items: [Account]) -> some View {
        HStack {
            Label(title, systemImage: "creditcard.fill")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Menu {
                if !items.isEmpty {
                    ForEach(items) { account in
                        Button(action: { selection.wrappedValue = account }) {
                            HStack {
                                Label(account.name, systemImage: account.icon)
                            }
                        }
                    }
                    Divider()
                }
                Button(action: { showingAddAccountSheet = true }) {
                    Label("Add New Account...", systemImage: "plus.circle")
                }
            } label: {
                HStack {
                    if let account = selection.wrappedValue {
                        Image(systemName: account.icon)
                        Text(account.name)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    } else {
                        Text(items.isEmpty ? "No Accounts" : "Select Account")
                            .foregroundColor(items.isEmpty ? .red : .secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(width: 200)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
    }

    private var notesInputView: some View {
        HStack(alignment: .top) {
            Label("Note", systemImage: "note.text")
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            TextField("Optional description...", text: $note, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
        }
        .frame(height: 60) // fixed height
    }
    
    private var receiptPickerView: some View {
        HStack {
            Label("Receipt", systemImage: "paperclip")
                .foregroundColor(.secondary)
            Spacer()
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let selectedImageData, let nsImage = NSImage(data: selectedImageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                } else {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("Upload")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(20)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
}
