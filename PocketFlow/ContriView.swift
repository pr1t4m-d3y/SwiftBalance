
//
//import SwiftUI
//import Charts
//
//struct ContriView: View {
//    @Environment(AppDataStore.self) private var store
//    @State private var rawSelection: Double? = nil
//    
//    // 1. We only need ONE state for navigation
//    @State private var selectedFriend: Friend? = nil
//    
//    var body: some View {
//        // ❌ REMOVED NavigationStack HERE. This fixes your "Back" button bug!
//        ScrollView {
//            VStack(spacing: 25) {
//                chartSection
//                friendsListSection
//                Spacer()
//            }
//            .padding(.top)
//        }
//        .background(Color(.systemGroupedBackground))
//        .navigationTitle("Contributions")
//        
//        // 2. THE ONLY NAVIGATION DESTINATION WE NEED
//        .navigationDestination(item: $selectedFriend) { friend in
//            // Pass the ID instead of a Binding. This is the secret to Instant Updates!
//            FriendDetailView(friendID: friend.id)
//        }
//    }
//    
//    // --- UI SECTIONS ---
//    
//    // Friend List Section
//    private var friendsListSection: some View {
//        VStack(spacing: 0) {
//            ForEach(store.friends) { friend in
//                Button(action: {
//                    selectedFriend = friend
//                }) {
//                    HStack {
//                        Text(friend.name).fontWeight(.semibold)
//                        Spacer()
//                        Text("₹\(Int(friend.totalOwed))").fontWeight(.bold)
//                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
//                    }
//                    .padding()
//                    .foregroundStyle(.primary)
//                }
//                Divider().padding(.leading)
//            }
//        }
//        .background(Color.white)
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//        .padding(.horizontal)
//    }
//    
//    private var chartSection: some View {
//        VStack(alignment: .leading, spacing: 15) {
//            Text("Owed to You").font(.headline).padding(.horizontal)
//            
//            VStack(spacing: 20) {
//                ZStack {
//                    Chart(store.friends, id: \.name) { item in
//                        SectorMark(
//                            angle: .value("Amount", item.totalOwed),
//                            innerRadius: .ratio(0.65),
//                            angularInset: 2
//                        )
//                        .cornerRadius(5)
//                        .foregroundStyle(item.color)
//                    }
//                    .frame(height: 280)
//                    .chartAngleSelection(value: $rawSelection)
//                    .onChange(of: rawSelection) { _, newValue in
//                        if let newValue { handleTap(value: newValue) }
//                    }
//                    
//                    VStack(spacing: 2) {
//                        Text("Highest Due").font(.caption).foregroundStyle(.secondary)
//                        Text("₹ \(Int(store.friends.map { $0.totalOwed }.max() ?? 0))")
//                            .font(.largeTitle).fontWeight(.bold)
//                    }
//                    .frame(width: 140, height: 140)
//                    .background(Color.white.opacity(0.001))
//                    .onTapGesture { }
//                }
//                
//                legendGrid
//            }
//            .padding(.vertical, 20)
//            .background(Color.white)
//            .clipShape(RoundedRectangle(cornerRadius: 16))
//            .shadow(color: .black.opacity(0.05), radius: 5)
//            .padding(.horizontal)
//        }
//    }
//    
//    private var legendGrid: some View {
//        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 10) {
//            ForEach(store.friends) { friend in
//                HStack(spacing: 6) {
//                    Circle().fill(friend.color).frame(width: 8, height: 8)
//                    Text(friend.name).font(.caption).fontWeight(.medium)
//                }
//            }
//        }
//        .padding(.horizontal)
//    }
//    
//    // --- HELPER LOGIC ---
//    func handleTap(value: Double) {
//        var accumulated = 0.0
//        for friend in store.friends {
//            let sliceSize = friend.totalOwed
//            let endRange = accumulated + sliceSize
//            if value >= accumulated && value <= endRange {
//                selectedFriend = friend
//                rawSelection = nil
//                return
//            }
//            accumulated = endRange
//        }
//    }
//}
//
//// MARK: - FRIEND DETAIL VIEW
//struct FriendDetailView: View {
//    @Environment(AppDataStore.self) private var store // Link directly to the brain
//    let friendID: UUID // We only need the ID to find the freshest data
//    
//    @State private var showPaymentSheet = false
//    @State private var paymentAmountString = ""
//    
//    // This always pulls the 100% latest data directly from the Store
//    var currentFriend: Friend? {
//        store.friends.first(where: { $0.id == friendID })
//    }
//    
//    var body: some View {
//        // Safely unwrap the live data
//        if let friend = currentFriend {
//            VStack {
//                VStack(spacing: 5) {
//                    Text("Total Outstanding").font(.subheadline).foregroundStyle(.secondary)
//                    Text("₹ \(Int(friend.totalOwed))")
//                        .font(.system(size: 44, weight: .bold, design: .rounded))
//                        .foregroundStyle(friend.totalOwed > 0 ? .red : .green)
//                        .contentTransition(.numericText()) // Smooth animation
//                }
//                .padding(.vertical, 30)
//                
//                List {
//                    Section(header: Text("Transaction History")) {
//                        ForEach(friend.history.sorted(by: { $0.date > $1.date })) { tx in
//                            HStack {
//                                VStack(alignment: .leading) {
//                                    Text(tx.note.isEmpty ? (tx.type == .debt ? "Added Debt" : "Payment Received") : tx.note).font(.headline)
//                                    Text(tx.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
//                                }
//                                Spacer()
//                                Text(tx.type == .debt ? "₹\(Int(tx.amount))" : "- ₹\(Int(tx.amount))")
//                                    .fontWeight(.bold).foregroundStyle(tx.type == .debt ? .red : .green)
//                            }
//                        }
//                    }
//                }
//                .listStyle(.insetGrouped)
//                
//                Button(action: { showPaymentSheet = true }) {
//                    HStack {
//                        Image(systemName: "banknote.fill")
//                        Text("Record Payment")
//                    }
//                    .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding()
//                    .background(Color.blue).clipShape(RoundedRectangle(cornerRadius: 15)).padding()
//                }
//            }
//            .navigationTitle(friend.name)
//            .sheet(isPresented: $showPaymentSheet) {
//                VStack(spacing: 20) {
//                    Text("Payment from \(friend.name)").font(.headline).padding(.top)
//                    TextField("Amount", text: $paymentAmountString)
//                        .keyboardType(.decimalPad).font(.title.bold()).multilineTextAlignment(.center).padding()
//                        .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
//                    
//                    Button(action: savePayment) {
//                        Text("Confirm Payment").fontWeight(.bold).frame(maxWidth: .infinity).padding()
//                            .background(Color.green).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
//                    }
//                    .padding(.horizontal).disabled(paymentAmountString.isEmpty)
//                    Spacer()
//                }
//                .presentationDetents([.height(300)])
//            }
//        }
//    }
//    
//    func savePayment() {
//        guard let amount = Double(paymentAmountString),
//              // Find the exact friend in the main store array
//              let index = store.friends.firstIndex(where: { $0.id == friendID }) else { return }
//        
//        let newTransaction = FriendTransaction(date: Date(), amount: amount, type: .payment, note: "Paid Back")
//        
//        // 🚨 CRITICAL FIX: Modifying the store array DIRECTLY triggers an instant UI update across the whole app
//        store.friends[index].history.append(newTransaction)
//        store.friends[index].totalOwed -= amount
//        
//        paymentAmountString = ""
//        showPaymentSheet = false
//    }
//}


import SwiftUI
import Charts

struct ContriView: View {
    @Environment(AppDataStore.self) private var store
    @State private var rawSelection: Double? = nil
    @State private var selectedFriend: Friend? = nil
    
    // FIX: Isolates the Top 5 debtors for the beautiful chart
    var topFriends: [Friend] {
        Array(store.friends.sorted(by: { $0.totalOwed > $1.totalOwed }).prefix(5))
    }
    
    // FIX: Sorts the entire list below so the highest balances are always at the top
    var allFriendsSorted: [Friend] {
        store.friends.sorted(by: { $0.totalOwed > $1.totalOwed })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                chartSection
                friendsListSection
                Spacer()
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Contributions")
        .navigationDestination(item: $selectedFriend) { friend in
            FriendDetailView(friendID: friend.id)
        }
    }

    // --- UI SECTIONS ---

    private var friendsListSection: some View {
        VStack(spacing: 0) {
            ForEach(allFriendsSorted) { friend in
                Button(action: { selectedFriend = friend }) {
                    HStack {
                        Text(friend.name).fontWeight(.semibold)
                        Spacer()
                        Text("₹\(Int(friend.totalOwed))").fontWeight(.bold)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .padding().foregroundStyle(.primary)
                }
                Divider().padding(.leading)
            }
        }
        .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Top 5 Owed to You").font(.headline).padding(.horizontal)

            VStack(spacing: 20) {
                ZStack {
                    Chart(topFriends, id: \.name) { item in
                        SectorMark(
                            angle: .value("Amount", item.totalOwed),
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
                        Text("Highest Due").font(.caption).foregroundStyle(.secondary)
                        Text("₹ \(Int(topFriends.first?.totalOwed ?? 0))")
                            .font(.largeTitle).fontWeight(.bold)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.white.opacity(0.001))
                    .onTapGesture { }
                }

                legendGrid
            }
            .padding(.vertical, 20).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5).padding(.horizontal)
        }
    }

    private var legendGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 10) {
            ForEach(topFriends) { friend in
                HStack(spacing: 6) {
                    Circle().fill(friend.color).frame(width: 8, height: 8)
                    Text(friend.name).font(.caption).fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal)
    }

    func handleTap(value: Double) {
        var accumulated = 0.0
        for friend in topFriends {
            let sliceSize = friend.totalOwed
            let endRange = accumulated + sliceSize
            if value >= accumulated && value <= endRange {
                selectedFriend = friend
                rawSelection = nil
                return
            }
            accumulated = endRange
        }
    }
}

// MARK: - FRIEND DETAIL VIEW
struct FriendDetailView: View {
    @Environment(AppDataStore.self) private var store
    let friendID: UUID
    
    @State private var showPaymentSheet = false
    @State private var paymentAmountString = ""
    
    var currentFriend: Friend? {
        store.friends.first(where: { $0.id == friendID })
    }
    
    var body: some View {
        if let friend = currentFriend {
            VStack {
                VStack(spacing: 5) {
                    Text("Total Outstanding").font(.subheadline).foregroundStyle(.secondary)
                    Text("₹ \(Int(friend.totalOwed))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(friend.totalOwed > 0 ? .red : .green)
                        .contentTransition(.numericText())
                }.padding(.vertical, 30)
                
                List {
                    Section(header: Text("Transaction History")) {
                        ForEach(friend.history.sorted(by: { $0.date > $1.date })) { tx in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(tx.note.isEmpty ? (tx.type == .debt ? "Added Debt" : "Payment Received") : tx.note).font(.headline)
                                    Text(tx.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(tx.type == .debt ? "₹\(Int(tx.amount))" : "- ₹\(Int(tx.amount))")
                                    .fontWeight(.bold).foregroundStyle(tx.type == .debt ? .red : .green)
                            }
                        }
                    }
                }.listStyle(.insetGrouped)
                
                Button(action: { showPaymentSheet = true }) {
                    HStack {
                        Image(systemName: "banknote.fill")
                        Text("Record Payment")
                    }
                    .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding()
                    .background(Color.blue).clipShape(RoundedRectangle(cornerRadius: 15)).padding()
                }
            }
            .navigationTitle(friend.name)
            .toolbar {
                if let phone = friend.phoneNumber, let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Link(destination: url) {
                            Image(systemName: "phone.circle.fill").font(.title2).foregroundStyle(.green)
                        }
                    }
                }
            }
            .sheet(isPresented: $showPaymentSheet) {
                VStack(spacing: 20) {
                    Text("Payment from \(friend.name)").font(.headline).padding(.top)
                    TextField("Amount", text: $paymentAmountString)
                        .keyboardType(.decimalPad).font(.title.bold()).multilineTextAlignment(.center).padding()
                        .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
                    
                    Button(action: savePayment) {
                        Text("Confirm Payment").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                            .background(Color.green).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }.padding(.horizontal).disabled(paymentAmountString.isEmpty)
                    Spacer()
                }.presentationDetents([.height(300)])
            }
        }
    }
    
    func savePayment() {
        guard let amount = Double(paymentAmountString),
              let index = store.friends.firstIndex(where: { $0.id == friendID }) else { return }
        
        let newTransaction = FriendTransaction(date: Date(), amount: amount, type: .payment, note: "Paid Back")
        store.friends[index].history.append(newTransaction)
        store.friends[index].totalOwed -= amount
        
        paymentAmountString = ""
        showPaymentSheet = false
    }
}
