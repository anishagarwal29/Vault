import SwiftData
import SwiftUI
import Foundation

// MARK: - Transaction Model

/// Represents a single financial transaction (Income, Expense, or Transfer).
@Model
final class Transaction {
    // MARK: Properties
    var id: UUID
    var amount: Double
    var date: Date
    var note: String
    var type: TransactionType
    
    // Optional receipt image data
    var imageData: Data?
    
    // The currency code for this transaction (e.g., "SGD", "USD")
    var currency: String = "SGD" // Default currency
    
    // MARK: Relationships
    
    // The category associated with this transaction (e.g., "Food", "Salary")
    @Relationship(inverse: \Category.transactions)
    var category: Category?
    
    // The source account (for expense/transfer) or destination account (for income)
    @Relationship(inverse: \Account.transactions)
    var account: Account? 
    
    // Only for transfers: The account receiving the money
    @Relationship(inverse: \Account.transferInTransactions)
    var destinationAccount: Account? 
    
    // The subscription instance if this transaction was auto-generated

    var subscription: RecurringSubscription?
    
    // MARK: Initialization
    init(amount: Double, date: Date, note: String = "", type: TransactionType, category: Category? = nil, account: Account? = nil, destinationAccount: Account? = nil, imageData: Data? = nil, currency: String = "SGD", subscription: RecurringSubscription? = nil) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.note = note
        self.type = type
        self.category = category
        self.account = account
        self.destinationAccount = destinationAccount
        self.imageData = imageData
        self.currency = currency
        self.subscription = subscription
    }
}

/// Defines the type of financial transaction.
enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense
    case transfer
}

// MARK: - Category Model

/// Represents a category for classifying transactions (e.g., Food, Transport).
@Model
final class Category {
    // MARK: Properties
    var id: UUID
    var name: String
    var icon: String // SF Symbol name
    var colorHex: String // Hex string for the category color
    var type: TransactionType // Whether this is an Income or Expense category
    var isCustom: Bool // Flag to identify user-created vs default categories
    
    // MARK: Relationships
    
    // Transactions belonging to this category
    @Relationship
    var transactions: [Transaction]?
    
    // Budgets associated with this category
    @Relationship(deleteRule: .cascade)
    var budgets: [Budget]?
    
    // MARK: Initialization
    init(name: String, icon: String, colorHex: String, type: TransactionType, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.isCustom = isCustom
    }
    
    // MARK: Helpers
    /// Returns the SwiftUI Color object from the stored hex string
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Account Model

/// Represents a financial account or payment method (e.g., Cash, Bank Account, Credit Card).
@Model
final class Account {
    // MARK: Properties
    var id: UUID
    var name: String
    var icon: String // SF Symbol name
    var type: AccountType
    
    // MARK: Account Details (Optional)
    // Stores network as string raw value from CardNetwork enum if applicable
    var cardNetwork: String = "Visa"
    var cardNumber: String = ""
    var cvv: String = ""
    var expiryDate: String = "" // Format: MM/YY
    var cardHolderName: String = ""
    var issuingBank: String = "Other" // specific for DBS/UOB request (sg banks)
    
    // MARK: Relationships
    
    // Transactions where this is the primary account (Source for Expense/Transfer, Destination for Income)
    @Relationship
    var transactions: [Transaction]? 
    
    // Transactions where this is the destination (Transfers only)
    @Relationship
    var transferInTransactions: [Transaction]? 
    
    // Budgets assigned specifically to this account (e.g., Credit Card limit)
    @Relationship(deleteRule: .cascade)
    var budgets: [Budget]? 
    
    // Subscriptions paid via this account
    @Relationship(deleteRule: .cascade, inverse: \RecurringSubscription.account)
    var subscriptions: [RecurringSubscription]?
    
    // MARK: Initialization
    init(name: String, icon: String, type: AccountType, cardNetwork: String = "Visa", issuingBank: String = "Other", cardNumber: String = "", cvv: String = "", expiryDate: String = "", cardHolderName: String = "") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.type = type
        self.cardNetwork = cardNetwork
        self.issuingBank = issuingBank
        self.cardNumber = cardNumber
        self.cvv = cvv
        self.expiryDate = expiryDate
        self.cardHolderName = cardHolderName
    }
    
    // MARK: Helpers
    /// Returns the last 4 digits of the card number for display security.
    var last4: String {
        guard cardNumber.count >= 4 else { return "" }
        return String(cardNumber.suffix(4))
    }
}

// MARK: - Subscription Model

/// Represents a recurring payment subscription.
@Model
final class RecurringSubscription {
    var id: UUID
    var name: String
    var amount: Double
    var billingCycle: String // Keep for backwards compatibility or display? Let's use interval/unit logic.
    var startDate: Date
    var nextPaymentDate: Date
    var isActive: Bool
    var note: String
    var billingInterval: Int
    var billingUnit: String // "Month", "Year", "Week"
    var isFree: Bool
    var trialEndDate: Date? // Optional: If set, the subscription becomes paid after this date
    
    @Relationship
    var account: Account?
    
    // Transactions generated by this subscription
    @Relationship(deleteRule: .cascade, inverse: \Transaction.subscription)
    var transactions: [Transaction]?
    
    init(name: String, amount: Double, billingCycle: String = "Monthly", startDate: Date = Date(), nextPaymentDate: Date = Date(), isActive: Bool = true, note: String = "", billingInterval: Int = 1, billingUnit: String = "Month", isFree: Bool = false, trialEndDate: Date? = nil, account: Account? = nil) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.nextPaymentDate = nextPaymentDate
        self.isActive = isActive
        self.note = note
        self.billingInterval = billingInterval
        self.billingUnit = billingUnit
        self.isFree = isFree
        self.trialEndDate = trialEndDate
        self.account = account
    }
}

// MARK: - Budget Model

/// Represents a spending limit or income goal.
/// Can be associated with a Category, an Account, or both.
@Model
final class Budget {
    var id: UUID
    var amount: Double
    var period: String = "Monthly" // For future extensibility (Weekly, Yearly)
    var dateCreated: Date = Date() // Used for sorting budgets chronologically
    
    // MARK: Relationships
    
    // If set, limits the budget to a specific account (e.g., Food budget specifically for Credit Card)
    // If Category is nil and Account is set, it acts as a total spending limit for that account.
    @Relationship(inverse: \Account.budgets)
    var account: Account?
    
    // The category this budget tracks (e.g., Food). 
    // If Account is nil, applies to all expenses in this category.
    @Relationship(inverse: \Category.budgets)
    var category: Category?
    
    init(amount: Double, account: Account? = nil, category: Category? = nil) {
        self.id = UUID()
        self.amount = amount
        self.account = account
        self.category = category
        self.dateCreated = Date()
    }
}

// MARK: - Enums

/// Supported types of accounts.
enum AccountType: String, Codable, CaseIterable {
    case cash = "Cash"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case digitalWallet = "Digital Wallet"
    case bankAccount = "Bank Account"
    case savings = "Savings"
    case other = "Other"
}

/// Supported card networks.
enum CardNetwork: String, CaseIterable, Identifiable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case other = "Other"
    
    var id: String { rawValue }
}

/// specific banks for improved UI localization (Singapore context).
enum IssuingBank: String, CaseIterable, Identifiable, Codable {
    case dbs = "DBS"
    case uob = "UOB"
    case ocbc = "OCBC"
    case citi = "Citi"
    case hsbc = "HSBC"
    case sc = "Standard Chartered"
    case other = "Other"
    
    var id: String { rawValue }
}
// MARK: - Subscription Logic Extension

extension RecurringSubscription {
    
    /// Generates past transactions from the start date (or trial end date) up to today.
    /// This ensures that the transaction history accurately reflects the subscription costs.
    func generatePastTransactions(context: ModelContext) {
        let today = Date()
        var currentDate = startDate
        
        // Calculate the date component for the billing interval
        var dateComponent = DateComponents()
        if billingUnit == "Month" { dateComponent.month = billingInterval }
        else if billingUnit == "Week" { dateComponent.day = billingInterval * 7 }
        else if billingUnit == "Year" { dateComponent.year = billingInterval }
        
        // Safety checks
        if currentDate > today { return }
        if billingInterval <= 0 { return }
        
        // Find or create "Subscriptions" category
        // We use a fetch descriptor to find it
        let categoryName = "Subscriptions"
        var subscriptionCategory: Category?
        
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == categoryName })
        if let existing = try? context.fetch(descriptor).first {
            subscriptionCategory = existing
        } else {
            // Create new category
            let newCategory = Category(
                name: categoryName,
                icon: "repeat.circle.fill", // Suitable icon for subscriptions
                colorHex: "#A020F0", // Purple color
                type: .expense,
                isCustom: false
            )
            context.insert(newCategory)
            subscriptionCategory = newCategory
        }
        
        while currentDate <= today {
            // Check if this specific date falls within the free trial period
            let isWithinTrial = isFree && (trialEndDate == nil || currentDate <= trialEndDate!)
            // Note: If isFree was JUST toggled off by the expiration check, `self.isFree` might be false now,
            // but we need to check if `currentDate` was during the trial period?
            // Actually, if `isFree` is false (because trial ended), we should generate transactions for dates AFTER the trial ended.
            // But what about dates BEFORE the trial ended? They should still be free.
            // So we need to assume that if `trialEndDate` is set, dates before it were free.
            
            // Refined Logic (Checking `trialEndDate` property regardless of `isFree` flag):
            // If `trialEndDate` exists, any date before it is considered free.
            let isDateFree = (trialEndDate != nil && currentDate <= trialEndDate!) || (isFree && trialEndDate == nil)
            
            if !isDateFree {
                let transaction = Transaction(
                    amount: amount,
                    date: currentDate,
                    note: name,
                    type: .expense,
                    category: subscriptionCategory,
                    account: account,
                    currency: "SGD", // Default or fetch from settings? Using hardcoded specific to context for now or account currency if available.
                    subscription: self
                )
                context.insert(transaction)
            }
            
            // Advance date
            if let next = Calendar.current.date(byAdding: dateComponent, to: currentDate) {
                currentDate = next
            } else {
                break
            }
        }
    }
    
    /// Deletes all transactions automatically linked to this subscription.
    func deleteLinkedTransactions(context: ModelContext) {
        if let transactions = transactions {
            for transaction in transactions {
                context.delete(transaction)
            }
        }
    }
}
