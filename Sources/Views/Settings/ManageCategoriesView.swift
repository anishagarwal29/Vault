import SwiftUI
import SwiftData

// MARK: - ManageCategoriesView

struct ManageCategoriesView: View {
    // MARK: Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: Queries
    @Query(sort: \Category.name) private var categories: [Category]
    
    // MARK: State Properties
    @State private var showingAddSheet = false
    @State private var editingCategory: Category?
    @State private var selectedSegment: TransactionType = .expense
    
    // MARK: Computed Properties
    var filteredCategories: [Category] {
        categories.filter { $0.type == selectedSegment }
    }
    
    // MARK: Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Categories")
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
            
            // Segmented Control
            Picker("", selection: $selectedSegment) {
                Text("Expense").tag(TransactionType.expense)
                Text("Income").tag(TransactionType.income)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 10)
            
            // List
            List {
                ForEach(filteredCategories) { category in
                    CategoryRowView(
                        category: category,
                        onEdit: { editingCategory = category },
                        onDelete: { deleteCategory(category) }
                    )
                }
                .onDelete(perform: deleteCategories)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .sheet(isPresented: $showingAddSheet) {
            CategoryFormView(type: selectedSegment)
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormView(categoryToEdit: category, type: category.type)
        }
        
    }
    
    // MARK: Actions
    private func deleteCategory(_ category: Category) {
        modelContext.delete(category)
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = filteredCategories[index]
            modelContext.delete(category)
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(category.color)
                .frame(width: 32)
            
            Text(category.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Actions
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

// MARK: - CategoryFormView

struct CategoryFormView: View {
    // MARK: Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: Properties
    var categoryToEdit: Category?
    @State var type: TransactionType
    
    // MARK: Form State
    @State private var name = ""
    @State private var icon = "tag.fill"
    @State private var color = Color.blue
    
    // MARK: Icon Options
    let availableIcons = [
        "tag.fill", "cart.fill", "house.fill", "car.fill", "bolt.fill",
        "gamecontroller.fill", "fork.knife", "cup.and.saucer.fill",
        "cross.case.fill", "airplane", "gift.fill", "dollarsign.circle.fill",
        "tshirt.fill", "bag.fill", "books.vertical.fill", "graduationcap.fill",
        "pills.fill", "heart.fill", "star.fill", "bed.double.fill", "briefcase.fill"
    ]
    
    // MARK: Body
    var body: some View {
        VStack(spacing: 20) {
            Text(categoryToEdit == nil ? "New Category" : "Edit Category")
                .font(.headline)
            
            TextField("Category Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            ColorPicker("Color", selection: $color)
            
            VStack(alignment: .leading) {
                Text("Icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                        ForEach(availableIcons, id: \.self) { iconName in
                            Image(systemName: iconName)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(icon == iconName ? Color.accentColor.opacity(0.2) : Color.clear)
                                .foregroundColor(icon == iconName ? .accentColor : .primary)
                                .cornerRadius(8)
                                .onTapGesture {
                                    icon = iconName
                                }
                        }
                    }
                }
                .frame(height: 150)
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 350, height: 400) // Reduced height
        .onAppear {
            if let cat = categoryToEdit {
                name = cat.name
                icon = cat.icon
                color = cat.color
                type = cat.type
            }
        }
    }
    
    // MARK: Actions
    private func save() {
        if let cat = categoryToEdit {
            cat.name = name
            cat.icon = icon
            cat.colorHex = color.toHex() ?? "#0000FF"
        } else {
            let newCat = Category(
                name: name,
                icon: icon,
                colorHex: color.toHex() ?? "#0000FF",
                type: type,
                isCustom: true
            )
            modelContext.insert(newCat)
        }
        dismiss()
    }
}
