

import SwiftUI
import Charts

struct SplitPerson: Identifiable {
    let id = UUID()
    var name: String = ""
    var amount: Double = 0.0
    var isLocked: Bool = false
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }.tag(1)
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }.tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - 1. HOME VIEW
struct HomeView: View {
    @Environment(AppDataStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var inputAmount: String = ""
    @State private var isCredit: Bool = false
    
    @State private var isExpanded: Bool = false
    @State private var activeTxID: UUID? = nil
    @State private var category: String = "Select Category"
    @State private var note: String = ""
    @State private var showCategoryWarning: Bool = false
    
    @State private var isContriMode: Bool = false
    @State private var splits: [SplitPerson] = []
    
    // UI FIX: Tells the keyboard where to jump
    @FocusState private var focusedSplitID: UUID?
    
    @State private var backgroundDate: Date? = nil
    let categories = ["Food", "Travel", "Entmt", "Groceries", "Misc", "Other"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if !isExpanded {
                    VStack {
                        Text("Available Balance").font(.subheadline).foregroundStyle(.secondary)
                        Text("₹ \(Int(store.totalBalance))")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(store.totalBalance < 0 ? .red : .primary)
                            .contentTransition(.numericText())
                    }
                    .padding(.vertical, 25).frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1)).clipShape(Capsule()).padding(.horizontal)
                    .transition(.opacity.combined(with: .scale))
                }

                if isExpanded {
                    Button(action: cancelAndEditAmount) {
                        Text("₹ \(inputAmount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                            .foregroundStyle(isCredit ? .green : .red)
                    }
                    .frame(maxWidth: .infinity)
                    .transition(.scale.combined(with: .opacity))
                    
                } else {
                    HStack(spacing: 15) {
                        TextField("0", text: $inputAmount).keyboardType(.decimalPad)
                            .font(.system(size: 24, weight: .semibold)).padding()
                            .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 15))
                        
                        Picker("Type", selection: $isCredit) {
                            Text("Spend").tag(false)
                            Text("Credit").tag(true)
                        }.pickerStyle(.segmented).frame(width: 120)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                if !isExpanded {
                    Button(action: startLogging) {
                        Text("Log Transaction").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                            .background(isCredit ? Color.green : Color.red).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 15))
                    }.padding(.horizontal).disabled(inputAmount.isEmpty)
                } else {
                    expandedDetailsMenu
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .navigationTitle("PocketFlow").padding(.top)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isContriMode)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    backgroundDate = Date()
                } else if newPhase == .active {
                    if let bgDate = backgroundDate, Date().timeIntervalSince(bgDate) > 10 {
                        if isExpanded { forceReset() }
                    }
                    backgroundDate = nil
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    var expandedDetailsMenu: some View {
        VStack(spacing: 15) {
            HStack {
                if !isCredit {
                    if !isContriMode {
                        Menu {
                            ForEach(categories, id: \.self) { cat in
                                Button(cat) {
                                    category = cat
                                    showCategoryWarning = false
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category == "Select Category" ? "tag.fill" : "checkmark.circle.fill")
                                Text(category == "Select Category" ? "Category" : category).lineLimit(1)
                            }
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(showCategoryWarning ? Color.red.opacity(0.15) : Color.blue.opacity(0.1))
                            .foregroundStyle(showCategoryWarning ? Color.red : Color.blue)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(showCategoryWarning ? Color.red : Color.clear, lineWidth: 1.5))
                        }
                    } else {
                        Text("Contri").font(.subheadline.bold()).padding(.horizontal, 16).padding(.vertical, 14)
                            .background(Color.pink.opacity(0.1)).foregroundStyle(.pink).clipShape(Capsule())
                    }
                }
                
                TextField("Description...", text: $note)
                    .padding().background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 15))
            }.padding(.horizontal)
            
            if !isCredit {
                Toggle("Split as Contri", isOn: $isContriMode)
                    .padding(.horizontal).padding(.vertical, 8)
                    .onChange(of: isContriMode) { _, isOn in
                        if isOn {
                            category = "Contri"
                            let halfAmount = (Double(inputAmount) ?? 0) / 2
                            splits = [SplitPerson(amount: halfAmount)]
                            showCategoryWarning = false
                        } else {
                            category = "Select Category"
                            splits = []
                        }
                    }
                
                if isContriMode {
                    VStack(spacing: 10) {
                        ForEach($splits) { $split in
                            HStack {
                                TextField("Person Name", text: $split.name)
                                    // UI FIX: Link the focus state
                                    .focused($focusedSplitID, equals: split.id)
                                    .onSubmit { addNewSplitRow() }
                                    .submitLabel(.next)
                                    .padding().background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                TextField("Amount", value: $split.amount, format: .number)
                                    .keyboardType(.decimalPad)
                                    .onChange(of: split.amount) { _, _ in
                                        split.isLocked = true
                                        recalculateSplits()
                                    }
                                    .padding().frame(width: 100).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }.padding(.horizontal)
                }
            }
            
            Button(action: finalizeAndReset) {
                Text("Done").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 15))
            }.padding()
        }
    }
    
    func startLogging() {
        guard let amt = Double(inputAmount) else { return }
        if isCredit {
            note = "Pocket Money"
            category = "Income"
        }
        let newTx = Transaction(category: isCredit ? "Income" : "Select Category", amount: amt, date: Date(), isCredit: isCredit)
        store.addTransaction(newTx)
        activeTxID = newTx.id
        isExpanded = true
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cancelAndEditAmount() {
        if let id = activeTxID { store.transactions.removeAll { $0.id == id } }
        withAnimation {
            isExpanded = false
            activeTxID = nil
            if isCredit { note = "" }
        }
    }
    
    func addNewSplitRow() {
        let newSplit = SplitPerson(amount: 0)
        splits.append(newSplit)
        recalculateSplits()
        
        // UI FIX: Instantly jumps keyboard to the new row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusedSplitID = newSplit.id
        }
    }
    
    func recalculateSplits() {
        let total = Double(inputAmount) ?? 0
        let lockedSum = splits.filter { $0.isLocked }.reduce(0) { $0 + $1.amount }
        let unlockedCount = splits.filter { !$0.isLocked }.count
        
        if unlockedCount > 0 {
            let remaining = max(total - lockedSum, 0)
            let autoSplitAmount = remaining / Double(unlockedCount + 1)
            for i in 0..<splits.count {
                if !splits[i].isLocked { splits[i].amount = autoSplitAmount }
            }
        }
    }
    
    func finalizeAndReset() {
        if !isCredit && !isContriMode && category == "Select Category" {
            withAnimation { showCategoryWarning = true }
            return
        }
        
        if let id = activeTxID {
            store.updateTransaction(id: id, category: category, note: note)
            if !isCredit && isContriMode {
                let txNote = note.isEmpty ? "Split Expense" : note
                for split in splits {
                    store.addFriendDebt(name: split.name, amount: split.amount, date: Date(), note: txNote)
                }
            }
        }
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation { isExpanded = false }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            inputAmount = ""
            note = ""
            isContriMode = false
            activeTxID = nil
            splits = []
            category = "Select Category"
            showCategoryWarning = false
            isCredit = false
        }
    }
    
    func forceReset() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation { isExpanded = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            inputAmount = ""
            note = ""
            isContriMode = false
            activeTxID = nil
            splits = []
            category = "Select Category"
            showCategoryWarning = false
            isCredit = false
        }
    }
}

// MARK: - 2. HISTORY VIEW
struct HistoryView: View {
    @Environment(AppDataStore.self) private var store
    @State private var editingTx: Transaction? = nil
    
    @State private var editCategory: String = "Select Category"
    @State private var editNote: String = ""
    @State private var showCategoryWarning: Bool = false
    
    @State private var isContriMode: Bool = false
    @State private var splits: [SplitPerson] = []
    
    // UI FIX: Tells the keyboard where to jump
    @FocusState private var focusedSplitID: UUID?
    
    let categories = ["Food", "Travel", "Entmt", "Groceries", "Misc", "Other"]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.transactions.sorted(by: { $0.date > $1.date })) { tx in
                    HStack {
                        Image(systemName: tx.isCredit ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(tx.isCredit ? .green : .red).font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("₹ \(Int(tx.amount))").font(.headline).fontWeight(.bold)
                            HStack {
                                Text(tx.category).font(.subheadline).foregroundStyle(.secondary)
                                if tx.isDescriptionPending {
                                    Text("• Pending").font(.caption).bold().foregroundStyle(.orange)
                                } else {
                                    Text("• \(tx.note)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                        }
                        Spacer()
                        Text(tx.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editCategory = tx.category
                        editNote = tx.note
                        isContriMode = false
                        splits = []
                        showCategoryWarning = false
                        editingTx = tx
                    }
                }
            }
            .navigationTitle("History").listStyle(.insetGrouped)
            .sheet(item: $editingTx) { tx in
                VStack(spacing: 20) {
                    Text(tx.isCredit ? "Edit Income" : "Edit Expense").font(.headline).padding(.top, 10)
                    
                    HStack {
                        if !tx.isCredit {
                            if !isContriMode {
                                Menu {
                                    ForEach(categories, id: \.self) { cat in
                                        Button(cat) {
                                            editCategory = cat
                                            showCategoryWarning = false
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: editCategory == "Select Category" ? "tag.fill" : "checkmark.circle.fill")
                                        Text(editCategory == "Select Category" ? "Category" : editCategory).lineLimit(1)
                                    }
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(showCategoryWarning ? Color.red.opacity(0.15) : Color.blue.opacity(0.1))
                                    .foregroundStyle(showCategoryWarning ? Color.red : Color.blue)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(showCategoryWarning ? Color.red : Color.clear, lineWidth: 1.5))
                                }
                            } else {
                                Text("Contri").font(.subheadline.bold()).padding(.horizontal, 16).padding(.vertical, 14)
                                    .background(Color.pink.opacity(0.1)).foregroundStyle(.pink).clipShape(Capsule())
                            }
                        }
                        
                        TextField("Description...", text: $editNote)
                            .padding().background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 15))
                    }.padding(.horizontal)
                    
                    if !tx.isCredit {
                        Toggle("Split as Contri", isOn: $isContriMode)
                            .padding(.horizontal).padding(.vertical, 8)
                            .onChange(of: isContriMode) { _, isOn in
                                if isOn {
                                    editCategory = "Contri"
                                    splits = [SplitPerson(amount: tx.amount / 2)]
                                    showCategoryWarning = false
                                } else {
                                    editCategory = "Select Category"
                                    splits = []
                                }
                            }
                        
                        if isContriMode {
                            ScrollView {
                                VStack(spacing: 10) {
                                    ForEach($splits) { $split in
                                        HStack {
                                            TextField("Person Name", text: $split.name)
                                                // UI FIX: Link the focus state here too
                                                .focused($focusedSplitID, equals: split.id)
                                                .onSubmit {
                                                    let newSplit = SplitPerson(amount: 0)
                                                    splits.append(newSplit)
                                                    recalculateSplits(total: tx.amount)
                                                    
                                                    // UI FIX: Auto jump to new row
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                        focusedSplitID = newSplit.id
                                                    }
                                                }
                                                .submitLabel(.next)
                                                .padding().background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
                                            
                                            TextField("Amount", value: $split.amount, format: .number)
                                                .keyboardType(.decimalPad)
                                                .onChange(of: split.amount) { _, _ in
                                                    split.isLocked = true
                                                    recalculateSplits(total: tx.amount)
                                                }
                                                .padding().frame(width: 100).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }.padding(.horizontal)
                            }.frame(maxHeight: 150)
                        }
                    }
                    
                    Button(action: {
                        if !tx.isCredit && !isContriMode && editCategory == "Select Category" {
                            withAnimation { showCategoryWarning = true }
                            return
                        }
                        
                        store.updateTransaction(id: tx.id, category: editCategory, note: editNote)
                        
                        if !tx.isCredit && isContriMode {
                            let txNote = editNote.isEmpty ? "Split Expense" : editNote
                            for split in splits {
                                store.addFriendDebt(name: split.name, amount: split.amount, date: tx.date, note: txNote)
                            }
                        }
                        editingTx = nil
                    }) {
                        Text("Save").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                            .background(Color.blue).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 15))
                    }.padding()
                    Spacer()
                }
                // UI FIX: Increased minimum height from 250 to 300 so the title isn't cut off
                .presentationDetents(isContriMode ? [.height(400), .medium] : [.height(300)])
            }
        }
    }
    
    func recalculateSplits(total: Double) {
        let lockedSum = splits.filter { $0.isLocked }.reduce(0) { $0 + $1.amount }
        let unlockedCount = splits.filter { !$0.isLocked }.count
        
        if unlockedCount > 0 {
            let remaining = max(total - lockedSum, 0)
            let autoSplitAmount = remaining / Double(unlockedCount + 1)
            for i in 0..<splits.count {
                if !splits[i].isLocked { splits[i].amount = autoSplitAmount }
            }
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
