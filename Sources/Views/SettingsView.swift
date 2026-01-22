

// Reading file first before edit.
import SwiftData
import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    // MARK: Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    
    @AppStorage("currency") private var currency: String = "SGD"
    @AppStorage("theme") private var theme: String = "Dark"
    
    // Data Management State
    @State private var showingDeleteAlert = false
    
    // MARK: Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .shadow(color: .blue.opacity(0.5), radius: 10)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // List Layout
                    VStack(spacing: 24) {
                        
                        // Customization Section
                        SettingsSection(title: "Customization", icon: "paintbrush.fill", color: .purple) {
                            VStack(spacing: 0) {
                                NavigationLink(destination: ManageCategoriesView()) {
                                    SettingsListRow(icon: "tag.fill", title: "Categories", subtitle: "Manage tags")
                                }
                                .buttonStyle(.plain)
                                
                                Divider().opacity(0.1).padding(.horizontal, 16)

                                NavigationLink(destination: ManageBudgetsView()) {
                                    SettingsListRow(icon: "chart.pie.fill", title: "Budgets", subtitle: "Monthly limits")
                                }
                                .buttonStyle(.plain)
                                
                                Divider().opacity(0.1).padding(.horizontal, 16)
                                
                                NavigationLink(destination: ManageAccountsView()) {
                                    SettingsListRow(icon: "creditcard.fill", title: "Accounts", subtitle: "Cards, Wallets & Banks")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Preferences Section
                        SettingsSection(title: "Preferences", icon: "gear", color: .blue) {
                            VStack(spacing: 1) {
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .frame(width: 30)
                                        .foregroundColor(.white)
                                    Text("Currency")
                                    Spacer()
                                    
                                    NavigationLink(destination: ManageCurrenciesView()) {
                                        HStack(spacing: 4) {
                                            Text(currency)
                                                .foregroundColor(.secondary)
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary.opacity(0.3))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                
                            }
                        }
                        
                        // Data Section
                        SettingsSection(title: "Data Management", icon: "externaldrive.fill", color: .green) {
                            VStack(spacing: 1) {
                                Button(action: { showingDeleteAlert = true }) {
                                    SettingsListRow(icon: "trash", title: "Clear Data", subtitle: "Remove all transactions")
                                }
                                .buttonStyle(.plain)
                                
                            }
                        }
                        .alert("Clear All Data?", isPresented: $showingDeleteAlert) {
                            Button("Cancel", role: .cancel) { }
                            Button("Delete", role: .destructive) {
                                clearAllData()
                            }
                        } message: {
                            Text("This specific action will permanently delete ALL transactions. Categories and payment methods will be kept. This cannot be undone.")
                        }
                        
                        // About Section
                        SettingsSection(title: "About", icon: "info.circle.fill", color: .orange) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Finance Pro")
                                        .font(.headline)
                                    Text("Version 2.0 (Neon)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "app.dashed")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
    
    // MARK: Actions
    private func clearAllData() {
        do {
            try modelContext.delete(model: Transaction.self)
            print("All transactions deleted.")
        } catch {
            print("Failed to delete transactions: \(error)")
        }
    }
    
    
    
    
    
    
    // Styled Section Container
    // MARK: - SettingsSection Component
    struct SettingsSection<Content: View>: View {
        // MARK: Properties
        let title: String
        let icon: String
        let color: Color
        let content: () -> Content
        
        // MARK: Init
        init(title: String, icon: String, color: Color, @ViewBuilder content: @escaping () -> Content) {
            self.title = title
            self.icon = icon
            self.color = color
            self.content = content
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    content()
                }
                .background(Color.white.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, 4) // Outer padding
        }
    }
    
    // MARK: - SettingsListRow Component
    struct SettingsListRow: View {
        // MARK: Properties
        let icon: String
        let title: String
        let subtitle: String
        
        @State private var isHovering = false
        
        // MARK: Body
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.3))
            }
            .padding()
            .background(Color.white.opacity(isHovering ? 0.05 : 0))
            .onHover { isHovering = $0 }
        }
    }
    
    // MARK: - ManageCurrenciesView
    
    struct ManageCurrenciesView: View {
        // MARK: Properties
        @AppStorage("currency") private var currency: String = "SGD"
        // Single source of truth for ALL available currencies (defaults + custom)
        @AppStorage("enabledCurrencies") private var enabledCurrenciesString: String = "SGD,USD,EUR,INR,GBP,JPY,CNY,AUD,CAD"
        
        @State private var showingAddAlert = false
        @State private var newCode = ""
        
        var allCurrencies: [String] {
            enabledCurrenciesString.split(separator: ",").map { String($0) }.sorted()
        }
        
        // MARK: Body
        var body: some View {
            ZStack {
                Color.clear
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // Header
                        HStack {
                            Text("Manage Currencies")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .shadow(color: .blue.opacity(0.3), radius: 10)
                            
                            Spacer()
                            
                            Button(action: {
                                newCode = ""
                                showingAddAlert = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.accentColor)
                                    .shadow(color: .accentColor.opacity(0.4), radius: 5)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        if allCurrencies.isEmpty {
                            Text("No currencies available. Please add one.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            VStack(spacing: 1) {
                                ForEach(allCurrencies, id: \.self) { code in
                                    CurrencyRowView(
                                        code: code,
                                        isSelected: currency == code,
                                        onSelect: { currency = code },
                                        onDelete: { deleteCurrency(code) }
                                    )
                                    if code != allCurrencies.last {
                                        Divider().opacity(0.1).padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color.white.opacity(0.02))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .frame(minWidth: 500, minHeight: 600)
            .alert("Add Currency", isPresented: $showingAddAlert) {
                TextField("Code (e.g. THB)", text: $newCode)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    addCurrency()
                }
            } message: {
                Text("Enter the 3-letter currency code.")
            }
        }
        
        // MARK: Actions
        private func addCurrency() {
            let code = newCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard !code.isEmpty else { return }
            
            var current = allCurrencies
            if !current.contains(code) {
                current.append(code)
                enabledCurrenciesString = current.joined(separator: ",")
            }
            currency = code
        }
        
        private func deleteCurrency(_ code: String) {
            var current = allCurrencies
            current.removeAll { $0 == code }
            enabledCurrenciesString = current.joined(separator: ",")
            
            // If the selected currency was deleted, reset to a save default or the first available
            if currency == code {
                currency = current.first ?? "USD"
            }
        }
    }
    
    // MARK: - CurrencyRowView Component
    struct CurrencyRowView: View {
        let code: String
        let isSelected: Bool
        let onSelect: () -> Void
        let onDelete: (() -> Void)?
        
        @State private var isHovering = false
        
        var body: some View {
            HStack {
                // Icon / Check
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(code)
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.leading, 8)
                
                Spacer()
                
                Button(action: { onDelete?() }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .opacity(isHovering ? 1 : 0.6)
                }
                .buttonStyle(.plain)
                .help("Delete Currency")
            }
            .padding()
            .background(Color.white.opacity(isHovering ? 0.08 : 0.001)) // Subtle highlight
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            .onHover { isHovering = $0 }
        }
    }
    
}
