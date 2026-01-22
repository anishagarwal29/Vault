import SwiftUI
import SwiftData


struct AddSubscriptionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var account: Account
    var subscriptionToEdit: RecurringSubscription? // Optional for edit mode
    
    // MARK: - State Properties
    @State private var name: String = ""
    @State private var isFree: Bool = false
    @State private var amount: Double = 0.0
    @State private var intervalValue: Int = 1
    @State private var intervalUnit: String = "Month" // "Week", "Month", "Year"
    @State private var isActive: Bool = true
    @State private var startDate: Date = Date()
    @State private var notes: String = ""
    @State private var trialDurationValue: Int = 1
    @State private var trialDurationUnit: String = "Month"

    
    let currency: String = "SGD"
    
    init(account: Account, subscriptionToEdit: RecurringSubscription? = nil) {
        self.account = account
        self.subscriptionToEdit = subscriptionToEdit
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        nameSection
                        mainOptionsSection
                        notesSection
                    }
                    .padding(24)
                }
                
                footerView
            }
            .frame(width: 500, height: 650)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(24)
            .shadow(radius: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .onAppear { loadSubscriptionData() }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(white: 0.2)))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(subscriptionToEdit != nil ? "Edit Subscription" : "Add Subscription")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Spacer().frame(width: 32)
        }
        .padding(20)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription Name")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("e.g. Netflix, Spotify, Apple Music", text: $name)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(white: 0.15))
                .cornerRadius(12)
                .foregroundColor(.white)
                .font(.system(size: 16))
        }
    }
    
    private var mainOptionsSection: some View {
        VStack(spacing: 0) {
            pricingSection
            Divider().background(Color.white.opacity(0.1))
            schedulingSection
        }
        .background(Color(white: 0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var pricingSection: some View {
        Group {
            // Free / Trial Toggle
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text("Free / Trial")
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $isFree)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding(16)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Amount
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text("Amount")
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 0) {
                    Text(currency)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 8)
                    
                    TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .frame(width: 100)
                }
                .background(Color(white: 0.18))
                .cornerRadius(8)
                .opacity(isFree ? 0.5 : 1.0)
            }
            .padding(20)
            
            if isFree {
                Divider().background(Color.white.opacity(0.1))
                trialDurationSection
            }
        }
    }
    
    private var trialDurationSection: some View {
        Group {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text("Free Trial Duration")
                    .foregroundColor(.white)
                    .layoutPriority(1) // Ensure label isn't crushed
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { if trialDurationValue > 1 { trialDurationValue -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(trialDurationValue)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(minWidth: 20)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { trialDurationValue += 1 }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    
                    // Vertical Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 16)
                    
                    // Unit Toggle
                    Menu {
                        Button("Days") { trialDurationUnit = "Day" }
                        Button("Weeks") { trialDurationUnit = "Week" }
                        Button("Months") { trialDurationUnit = "Month" }
                    } label: {
                        HStack(spacing: 4) {
                            Text(trialDurationUnit)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fixedSize() // Prevent text wrapping/truncation
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.blue.opacity(0.7))
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize() // Important: stops menu from being crushed
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color(white: 0.18))
                .cornerRadius(8)
            }
            .padding(20)
            
            Text("Subscription will automatically become paid after trial ends.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
    }
    
    private var schedulingSection: some View {
        Group {
            // Billing Interval
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text("Billing Interval")
                    .foregroundColor(.white)
                    .layoutPriority(1)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { if intervalValue > 1 { intervalValue -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    
                    Text("Every \(intervalValue) \(intervalUnit.lowercased())\(intervalValue > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .fixedSize() // Ensure full text is shown
                    
                    Button(action: { intervalValue += 1 }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color(white: 0.18))
                .cornerRadius(8)
            }
            .padding(20)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Status
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text("Status")
                    .foregroundColor(.white)
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isActive.toggle() } }) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(isActive ? Color.green : Color.white.opacity(0.1))
                                    .frame(width: 24, height: 24)
                                
                                if isActive {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Text(isActive ? "Active" : "Cancelled")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(isActive ? .green : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color(white: 0.18))
                .cornerRadius(20)
            }
            .padding(20)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Start Date
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                Text("Start Date")
                    .foregroundColor(.white)
                Spacer()
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
            .padding(20)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.gray)
                Text("Notes")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Optional notes...")
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $notes)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color(white: 0.15))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .frame(height: 100)
            }
        }
    }
    
    private var footerView: some View {
        VStack {
            Button(action: handleSave) {
                Text(subscriptionToEdit != nil ? "Save Changes" : "Add Subscription")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
    
    private func loadSubscriptionData() {
        if let sub = subscriptionToEdit {
            name = sub.name
            amount = sub.amount
            isActive = sub.isActive
            isFree = sub.isFree
            startDate = sub.startDate
            notes = sub.note
            intervalValue = sub.billingInterval
            intervalUnit = sub.billingUnit
        }
    }
    
    // MARK: - Logic
    
    private func handleSave() {
        let billingString = "Every \(intervalValue) \(intervalUnit.lowercased())\(intervalValue > 1 ? "s" : "")"
        
        // Calculate Next Payment Date (Simple logic for now)
        var dateComponent = DateComponents()
        if intervalUnit == "Month" { dateComponent.month = intervalValue }
        else if intervalUnit == "Week" { dateComponent.day = intervalValue * 7 }
        else if intervalUnit == "Year" { dateComponent.year = intervalValue }
        
        let nextDate = Calendar.current.date(byAdding: dateComponent, to: startDate) ?? startDate
        
        // Store the correct amount so it can be used after the trial ends
        let finalAmount = amount
        
        var trialEnd: Date? = nil
        if isFree {
            var component = DateComponents()
            if trialDurationUnit == "Day" { component.day = trialDurationValue }
            else if trialDurationUnit == "Week" { component.day = trialDurationValue * 7 }
            else if trialDurationUnit == "Month" { component.month = trialDurationValue }
            trialEnd = Calendar.current.date(byAdding: component, to: startDate)
        }

        if let sub = subscriptionToEdit {
            // EDIT MODE
            
            // Detect significant changes that require history regeneration
            let amountChanged = sub.amount != amount
            let dateChanged = sub.startDate != startDate
            let intervalChanged = sub.billingInterval != intervalValue || sub.billingUnit != intervalUnit
            let statusChanged = sub.isActive != isActive
            let freeChanged = sub.isFree != isFree
            
            // If significant properties changed, we wipe the history to regenerate it accurately
            if amountChanged || dateChanged || intervalChanged || (statusChanged && isActive) || (freeChanged && !isFree) {
                 sub.deleteLinkedTransactions(context: modelContext)
            }
            
            // Update properties
            sub.name = name
            sub.amount = amount // Store the user input amount always
            sub.billingCycle = billingString
            sub.startDate = startDate
            // Update next payment date if timing changed
            if dateChanged || intervalChanged {
                 sub.nextPaymentDate = nextDate
            }
            sub.isActive = isActive
            sub.note = notes
            sub.billingInterval = intervalValue
            sub.billingUnit = intervalUnit
            sub.isFree = isFree
            sub.trialEndDate = trialEnd
            
            // Regenerate if valid and active
            // Modified logic: Only generate if it's NOT a trial (or trial finished?) or if we support generating "Free" transactions (0 value)?
            // User requested: "auto changes to become paid". This implies we start generating ONLY after trial ends.
            // If isFree is currently true, we generally DON'T generate transactions yet?
            // "UNLESS its canceeled".
            
            if isActive {
                sub.generatePastTransactions(context: modelContext)
            }
            
        } else {
            // CREATE MODE
            let newSub = RecurringSubscription(
                name: name,
                amount: amount, // Store the future amount
                billingCycle: billingString,
                startDate: startDate,
                nextPaymentDate: nextDate,
                isActive: isActive,
                note: notes,
                billingInterval: intervalValue,
                billingUnit: intervalUnit,
                isFree: isFree,
                trialEndDate: trialEnd,
                account: account
            )
            modelContext.insert(newSub)
            
            // Generate Past Transactions 
            if isActive {
                newSub.generatePastTransactions(context: modelContext)
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
    

}
