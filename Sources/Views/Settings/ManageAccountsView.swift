import SwiftUI
import SwiftData

struct ManageAccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.name) private var accounts: [Account]
    
    @State private var showingAddSheet = false
    @State private var editingAccount: Account?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Accounts")
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
            
            // List
                List {
                    ForEach(accounts) { account in
                        AccountRowView(
                            account: account,
                            onEdit: { editingAccount = account },
                            onDelete: { deleteAccount(account) }
                        )
                    }
                    .onDelete(perform: deleteAccounts)
                }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .sheet(isPresented: $showingAddSheet) {
            AccountFormView()
                .presentationDetents([.fraction(0.85)])
        }
        .sheet(item: $editingAccount) { account in
            AccountFormView(accountToEdit: account)
                .presentationDetents([.fraction(0.85)])
        }
    }
    
    private func deleteAccount(_ account: Account) {
        modelContext.delete(account)
    }
    
    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(accounts[index])
        }
    }
}

struct AccountRowView: View {
    let account: Account
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.icon)
                .font(.title3)
                .foregroundColor(.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Actions
            // Actions
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

struct AccountFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var accountToEdit: Account?
    
    @State private var name = ""
    @State private var type: AccountType = .creditCard
    @State private var cardNetwork: CardNetwork = .visa
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var monthlySpendingLimit: Double? = nil
    @State private var cardHolderName = ""
    @State private var issuingBank: IssuingBank = .other
    
    // Auto-detect network hook
    private func detectNetwork(from number: String) {
        let clean = number.replacingOccurrences(of: " ", with: "")
        
        if clean.isEmpty { return }
        
        if clean.hasPrefix("4") {
            cardNetwork = .visa
        } else if clean.hasPrefix("5") || clean.hasPrefix("2") {
            cardNetwork = .mastercard
        } else {
            // Fallback to Other for unknown prefixes (including Amex/Discover which are now unsupported)
            cardNetwork = .other
        }
    }
    
    // Computed icon based on type/network
    var computedIcon: String {
        switch type {
        case .cash: return "banknote.fill"
        case .creditCard, .debitCard: return "creditcard.fill"
        case .digitalWallet: return "iphone.gen3"
        case .bankAccount, .savings: return "building.columns.fill"
        case .other: return "wallet.pass.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(accountToEdit == nil ? "Add Account" : "Edit Account")
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Card Preview
                    ZStack {
                        // Background
                        RoundedRectangle(cornerRadius: 16)
                            .fill(cardGradient)
                            .shadow(radius: 10, y: 5)
                        
                        // Noise overlay (simulation)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "wave.3.right")
                                    .opacity(0.8)
                                    .opacity(0.8)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(cardNetwork.rawValue.uppercased())
                                        .font(.system(size: 14, weight: .bold, design: .serif))
                                        .italic()
                                    if issuingBank != .other {
                                        Text(issuingBank.rawValue.uppercased())
                                            .font(.system(size: 10, weight: .semibold))
                                            .opacity(0.8)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Masked Card Number
                            HStack(spacing: 4) {
                                if !cardNumber.isEmpty {
                                    // Logic: show digits as bullets except last 4
                                    // But input has spaces. Let's process the raw digits.
                                    let raw = cardNumber.replacingOccurrences(of: " ", with: "")
                                    let totalLength = 16 // standard
                                    
                                    ForEach(0..<4) { chunkIndex in
                                        let start = chunkIndex * 4
                                        let end = min(start + 4, raw.count)
                                        
                                        if start < raw.count {
                                            // Get this chunk's content
                                            let chunkStr = String(raw[raw.index(raw.startIndex, offsetBy: start)..<raw.index(raw.startIndex, offsetBy: end)])
                                            
                                            // If it's the last chunk (indices 12-15) show digits, else show dots
                                            if chunkIndex == 3 {
                                                Text(chunkStr)
                                                    .font(.system(.title2, design: .monospaced))
                                                    .fontWeight(.bold)
                                            } else {
                                                // If we have chars here, show dots
                                                HStack(spacing: 2) {
                                                    ForEach(0..<chunkStr.count, id: \.self) { _ in
                                                        Circle().frame(width: 6, height: 6)
                                                    }
                                                    // Fill remaining spaces in this chunk with empty if partial? 
                                                    // Actually simplest is just:
                                                }
                                                .frame(width: 50, alignment: .leading) // Fixed width for alignment
                                            }
                                        } else {
                                            // Placeholder dots for empty chunks
                                            HStack(spacing: 2) {
                                                ForEach(0..<4) { _ in Circle().frame(width: 6, height: 6).opacity(0.3) }
                                            }
                                            .frame(width: 50, alignment: .leading)
                                        }
                                        
                                        if chunkIndex < 3 {
                                            Spacer().frame(width: 10)
                                        }
                                    }
                                } else {
                                    // Empty state
                                    Text("•••• •••• •••• ••••")
                                        .font(.system(.title2, design: .monospaced))
                                        .opacity(0.5)
                                }
                            }
                            .shadow(radius: 2)
                            
                            Spacer()
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("CARD HOLDER")
                                        .font(.caption2)
                                        .opacity(0.7)
                                    Text(cardHolderName.isEmpty ? "YOUR NAME" : cardHolderName.uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading) {
                                    Text("EXPIRES")
                                        .font(.caption2)
                                        .opacity(0.7)
                                    Text(expiryDate.isEmpty ? "MM/YY" : expiryDate)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .padding(24)
                        .foregroundColor(.white)
                    }
                    .frame(height: 220)
                    .padding(.horizontal)
                    
                    // Fields
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Type & Network
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Type").font(.caption).foregroundColor(.secondary)
                                Picker("Type", selection: $type) {
                                    ForEach(AccountType.allCases, id: \.self) { t in
                                        Text(t.rawValue).tag(t)
                                    }
                                }
                                .labelsHidden()
                            }
                            
                            if type == .creditCard || type == .debitCard {
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Network").font(.caption).foregroundColor(.secondary)
                                    Picker("Network", selection: $cardNetwork) {
                                        ForEach(CardNetwork.allCases) { net in
                                            Text(net.rawValue).tag(net)
                                        }
                                    }
                                    .labelsHidden()
                                }
                                
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Bank").font(.caption).foregroundColor(.secondary)
                                    Picker("Bank", selection: $issuingBank) {
                                        ForEach(IssuingBank.allCases) { bank in
                                            Text(bank.rawValue).tag(bank)
                                        }
                                    }
                                    .labelsHidden()
                                }
                            }
                        }
                        
                        // Account Name
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Account Name").font(.caption).foregroundColor(.secondary)
                            TextField(generatedNamePlaceholder, text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Card Number (Only if relevant)
                        if type == .creditCard || type == .debitCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Card Number").font(.caption).foregroundColor(.secondary)
                                TextField("0000 0000 0000 0000", text: $cardNumber)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                                    .onChange(of: cardNumber) { _, newValue in
                                        formatCardNumber(newValue)
                                        detectNetwork(from: newValue)
                                    }
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Expiry").font(.caption).foregroundColor(.secondary)
                                    TextField("MM/YY", text: $expiryDate)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: expiryDate) { _, newValue in
                                            formatExpiryDate(newValue)
                                        }
                                }
                                .frame(width: 100)
                                
                                Spacer()
                                
                                /*
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CVV").font(.caption).foregroundColor(.secondary)
                                    TextField("123", text: $cvv)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                                */
                            }
                            
                            TextField("Cardholder Name", text: $cardHolderName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        
        // Footer
        HStack {
            Button("Cancel", role: .cancel) { dismiss() }
            Spacer()
            Button("Save") { save() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
    .frame(width: 450, height: 650)
    .onAppear {
        if let account = accountToEdit {
            name = account.name
            type = account.type
            // Try to match network if stored strings, else default
            if let net = CardNetwork(rawValue: account.cardNetwork) {
                cardNetwork = net
            }
            if let bank = IssuingBank(rawValue: account.issuingBank) {
                issuingBank = bank
            }
            cardNumber = account.cardNumber
            expiryDate = account.expiryDate
            cvv = account.cvv
            cardHolderName = account.cardHolderName
        }
    }
}
    
    private var cardGradient: LinearGradient {
        switch cardNetwork {
        case .visa:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mastercard:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:
            return LinearGradient(colors: [.black, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // Auto-formatting Functions
    
    private func formatCardNumber(_ val: String) {
        // Remove spaces
        let digits = val.filter { "0123456789".contains($0) }
        
        // Cap at 16
        let capped = String(digits.prefix(16))
        
        // Add spaces every 4
        var result = ""
        for (i, char) in capped.enumerated() {
            if i > 0 && i % 4 == 0 {
                result += " "
            }
            result.append(char)
        }
        
        // Prevent recursive loop if no change
        if cardNumber != result {
            cardNumber = result
        }
    }
    
    private func formatExpiryDate(_ val: String) {
        // Remove non-digits
        var digits = val.filter { "0123456789".contains($0) }
        
        // Cap at 4 (MMYY)
        digits = String(digits.prefix(4))
        
        if digits.count >= 3 {
            // Insert slash
            let mm = digits.prefix(2)
            let yy = digits.suffix(digits.count - 2)
            let result = "\(mm)/\(yy)"
            if expiryDate != result { expiryDate = result }
        } else {
            if expiryDate != digits { expiryDate = digits }
        }
    }
    
    var generatedNamePlaceholder: String {
        if type == .creditCard || type == .debitCard {
            let clean = cardNumber.replacingOccurrences(of: " ", with: "")
            let last4 = String(clean.suffix(4))
            if !last4.isEmpty {
                return "\(cardNetwork.rawValue) •••• \(last4)"
            } else {
                return "\(cardNetwork.rawValue) (No Number)"
            }
        } else {
            return type.rawValue
        }
    }
    
    private func save() {
        let finalName: String
        if !name.isEmpty {
            finalName = name
        } else {
            finalName = generatedNamePlaceholder
        }
        
        if let account = accountToEdit {
            account.name = finalName
            account.type = type
            account.cardNetwork = cardNetwork.rawValue
            account.issuingBank = issuingBank.rawValue
            account.cardNumber = cardNumber
            account.cvv = cvv
            account.expiryDate = expiryDate
            account.cardHolderName = cardHolderName
            account.icon = computedIcon
        } else {
            let newAccount = Account(
                name: finalName,
                icon: computedIcon,
                type: type,
                cardNetwork: cardNetwork.rawValue,
                issuingBank: issuingBank.rawValue,
                cardNumber: cardNumber,
                cvv: cvv,
                expiryDate: expiryDate,
                cardHolderName: cardHolderName
            )
            modelContext.insert(newAccount)
        }
        dismiss()
    }
}
