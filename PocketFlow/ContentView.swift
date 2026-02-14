import SwiftUI
import Charts

// MARK: - CONTENT VIEW (Main Tab Controller)
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(1)
            
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - 1. HOME VIEW
struct HomeView: View {
    @Environment(AppDataStore.self) private var store
    @State private var inputAmount: String = ""
    @State private var isCredit: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Balance Header
                VStack {
                    Text("Available Balance")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("₹ \(Int(store.totalBalance))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
                .padding(.vertical, 25).frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1)).clipShape(Capsule()).padding(.horizontal)

                // Input Box
                HStack(spacing: 15) {
                    TextField("0", text: $inputAmount).keyboardType(.decimalPad)
                        .font(.system(size: 24, weight: .semibold)).padding()
                        .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Picker("Type", selection: $isCredit) {
                        Text("Spend").tag(false)
                        Text("Credit").tag(true)
                    }.pickerStyle(.segmented).frame(width: 120)
                }.padding(.horizontal)

                // Log Button
                Button(action: {
                    if let amt = Double(inputAmount) {
                        let newTx = Transaction(category: "General", amount: amt, date: Date(), isCredit: isCredit)
                        store.addTransaction(newTx)
                        inputAmount = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                    }
                }) {
                    Text("Log Transaction").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                        .background(isCredit ? Color.green : Color.red).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 15))
                }.padding(.horizontal).disabled(inputAmount.isEmpty)
                
                Spacer()
            }
            .navigationTitle("PocketFlow").padding(.top)
        }
    }
}

// MARK: - 2. HISTORY VIEW
struct HistoryView: View {
    @Environment(AppDataStore.self) private var store
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.transactions.sorted(by: { $0.date > $1.date })) { tx in
                    HStack {
                        Image(systemName: tx.isCredit ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(tx.isCredit ? .green : .red).font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("₹ \(Int(tx.amount))").font(.headline).fontWeight(.bold)
                            Text(tx.category).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(tx.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("History").listStyle(.insetGrouped)
        }
    }
}

// MARK: - 3. DASHBOARD VIEW
struct DashboardView: View {
    @Environment(AppDataStore.self) private var store
    @State private var timeRange = "7 Days"
    let timeRanges = ["1 Day", "7 Days", "30 Days", "12 Months"]
    
    @State private var selectedCategoryForNav: String? = nil
    @State private var showContriDetail = false
    @State private var rawSelection: Double? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    chartCardSection
                    recentActivitySection
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationDestination(isPresented: $showContriDetail) { ContriView() }
            .navigationDestination(item: $selectedCategoryForNav) { category in
                CategoryDetailView(category: category, transactions: filteredTransactions)
            }
        }
    }
    
    // BREAKING UP THE VIEW TO HELP THE COMPILER
    private var chartCardSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Financial Breakdown").font(.headline)
                Spacer()
                Picker("Range", selection: $timeRange) {
                    ForEach(timeRanges, id: \.self) { Text($0) }
                }.pickerStyle(.menu)
            }.padding(.horizontal)
            
            VStack(spacing: 20) {
                ZStack {
                    Chart(chartData, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.65),
                            angularInset: 2
                        )
                        .cornerRadius(5)
                        .foregroundStyle(item.color)
                    }
                    .frame(height: 280)
                    .chartAngleSelection(value: $rawSelection)
                    .onChange(of: rawSelection) { _, newValue in
                        if let newValue { handleTap(value: newValue) }
                    }
                    
                    VStack(spacing: 2) {
                        Text("Most Spent").font(.caption).foregroundStyle(.secondary)
                        Text("₹ \(Int(maxExpenseAmount))").font(.largeTitle).fontWeight(.bold)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.white.opacity(0.001))
                    .onTapGesture { }
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                    ForEach(chartData, id: \.category) { item in
                        HStack(spacing: 4) {
                            Circle().fill(item.color).frame(width: 8, height: 8)
                            Text(item.category).font(.caption).bold()
                        }
                    }
                }
            }
            .padding(.vertical, 20).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5).padding(.horizontal)
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity").font(.headline).padding(.horizontal)
            ForEach(filteredTransactions.prefix(15)) { tx in
                HStack {
                    Circle().fill(tx.color.opacity(0.2)).frame(width: 40, height: 40)
                        .overlay(Image(systemName: "cart.fill").font(.caption).foregroundStyle(tx.color))
                    VStack(alignment: .leading) {
                        Text(tx.category).font(.subheadline).bold()
                        Text(tx.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("- ₹\(Int(tx.amount))").font(.subheadline).bold()
                }
                .padding().background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
            }
        }
    }

    // LOGIC
    var filteredTransactions: [Transaction] {
        let cutoffDate: Date
        switch timeRange {
            case "1 Day": cutoffDate = Calendar.current.startOfDay(for: Date())
            case "7 Days": cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            case "30 Days": cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            case "12 Months": cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            default: cutoffDate = Date.distantPast
        }
        return store.transactions.filter { $0.date >= cutoffDate && !$0.isCredit }.sorted { $0.date > $1.date }
    }

    var chartData: [(category: String, amount: Double, color: Color)] {
        var data: [(category: String, amount: Double, color: Color)] = []
        let grouped = Dictionary(grouping: filteredTransactions, by: { $0.category })
        for (key, txs) in grouped {
            data.append((category: key, amount: txs.reduce(0) { $0 + $1.amount }, color: txs.first?.color ?? .gray))
        }
        data.append((category: "Contri", amount: store.totalContriAmount, color: .pink))
        return data.sorted { $0.amount > $1.amount }
    }
    
    var maxExpenseAmount: Double { chartData.first?.amount ?? 0 }
    
    func handleTap(value: Double) {
        var accumulated = 0.0
        for item in chartData {
            if value >= accumulated && value <= (accumulated + item.amount) {
                if item.category == "Contri" { showContriDetail = true }
                else { selectedCategoryForNav = item.category }
                break
            }
            accumulated += item.amount
        }
        rawSelection = nil
    }
}

// MARK: - 4. CATEGORY DETAIL VIEW
struct CategoryDetailView: View {
    let category: String
    let transactions: [Transaction]
    
    var body: some View {
        List {
            ForEach(transactions.filter { $0.category == category }) { tx in
                HStack {
                    VStack(alignment: .leading) {
                        Text(tx.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                        Text(tx.category).font(.headline)
                    }
                    Spacer()
                    Text("₹\(Int(tx.amount))").bold().foregroundStyle(Color.red)
                }
            }
        }
        .navigationTitle("\(category) History")
    }
}

#Preview {
    ContentView()
        .environment(AppDataStore())
}

