import SwiftUI
import SwiftData

// MARK: - ContentView

struct ContentView: View {
    // MARK: Properties
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Int = 0
    @State private var showAddSheet: Bool = false
    
    // MARK: Background Gradient
    private let bgGradient = LinearGradient(
        colors: [
            Color.black.opacity(0.95),
            Color(nsColor: .windowBackgroundColor)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: Body
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            bgGradient
                .ignoresSafeArea()
            
            // Subtle ambient neon orbs
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 600, height: 600)
                        .blur(radius: 100)
                        .offset(x: -200, y: -200)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 500, height: 500)
                        .blur(radius: 100)
                        .offset(x: proxy.size.width * 0.6, y: proxy.size.height * 0.4)
                }
            }
            .ignoresSafeArea()
            
            // Main Content
            ZStack {
                switch selectedTab {
                case 0:
                    DashboardView()
                case 1:
                    AllTransactionsView()
                case 2:
                    InsightsView()
                case 3:
                    SettingsView()
                default:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)
            
            // Custom Tab Bar
            HStack(spacing: 0) {
                TabBarButton(icon: "square.grid.2x2.fill", label: "Dashboard", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabBarButton(icon: "list.bullet.rectangle.portrait.fill", label: "Transactions", isSelected: selectedTab == 1) { selectedTab = 1 }
                
                Spacer().frame(width: 66)
                
                TabBarButton(icon: "chart.xyaxis.line", label: "Insights", isSelected: selectedTab == 2) { selectedTab = 2 }
                TabBarButton(icon: "gearshape.fill", label: "Settings", isSelected: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(width: 400) // Restored original friendly width for 4 items
            .background(
                GlassView(material: .hudWindow, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
            )
            .padding(.bottom, 20)
            
            // Floating Add Button
            Button(action: { showAddSheet = true }) {
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(gradient: Gradient(colors: [.cyan, .blue, .purple, .pink, .cyan]), center: .center)
                        )
                        .frame(width: 58, height: 58)
                        .blur(radius: 5)
                        .opacity(0.6)
                    
                    Circle()
                        .fill(LinearGradient(colors: [Color.cyan, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: Color.cyan.opacity(0.5), radius: 10, y: 5)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -34)
            .sheet(isPresented: $showAddSheet) {
                AddTransactionSheet()
                    .presentationBackground(.clear) // Transparent backdrop for custom modal look
            }
        }

    }
}

// MARK: - TabBarButton Component

struct TabBarButton: View {
    // MARK: Properties
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray)
                    .shadow(color: isSelected ? .white.opacity(0.6) : .clear, radius: 8)
                    .scaleEffect(isHovering ? 1.15 : 1.0)
                
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3, height: 3)
                        .shadow(radius: 2)
                        .matchedGeometryEffect(id: "tab_dot", in: Namespace().wrappedValue)
                } else {
                    Color.clear.frame(width: 3, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.spring(response: 0.3), value: isHovering)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
