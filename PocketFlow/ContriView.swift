import SwiftUI
import Charts

struct ContriView: View {
    @Environment(AppDataStore.self) private var store
    @State private var rawSelection: Double? = nil
    
    // 1. We only need ONE state for navigation
    @State private var selectedFriend: Friend? = nil
    
    var body: some View {
        NavigationStack {
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
            
            // 2. THE ONLY NAVIGATION DESTINATION WE NEED
            // This works for BOTH the chart taps and the list taps
            .navigationDestination(item: $selectedFriend) { friend in
                if let index = store.friends.firstIndex(where: { $0.id == friend.id }) {
                    FriendDetailView(friend: Bindable(store).friends[index])
                }
            }
        }
    }
    
    
    //Friend List Section
    private var friendsListSection: some View {
            VStack(spacing: 0) {
                ForEach(store.friends) { friend in
                    // Using a Button instead of NavigationLink prevents the "Double Navigation" crash
                    Button(action: {
                        selectedFriend = friend
                    }) {
                        HStack {
                            Text(friend.name).fontWeight(.semibold)
                            Spacer()
                            Text("₹\(Int(friend.totalOwed))").fontWeight(.bold)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                        .padding()
                        .foregroundStyle(.primary)
                    }
                    Divider().padding(.leading)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    // --- UI SECTIONS ---
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Owed to You").font(.headline).padding(.horizontal)
            
            VStack(spacing: 20) {
                ZStack {
                    Chart(store.friends, id: \.name) { item in
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
                        Text("₹ \(Int(store.friends.map { $0.totalOwed }.max() ?? 0))")
                            .font(.largeTitle).fontWeight(.bold)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.white.opacity(0.001))
                    .onTapGesture { }
                }
                
                legendGrid
            }
            .padding(.vertical, 20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5)
            .padding(.horizontal)
        }
    }
    
    private var legendGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 10) {
            ForEach(store.friends) { friend in
                HStack(spacing: 6) {
                    Circle().fill(friend.color).frame(width: 8, height: 8)
                    Text(friend.name).font(.caption).fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal)
    }
    

    
    // --- HELPER LOGIC ---
    
    func handleTap(value: Double) {
            var accumulated = 0.0
            for friend in store.friends {
                let sliceSize = friend.totalOwed
                let endRange = accumulated + sliceSize
                if value >= accumulated && value <= endRange {
                    // This triggers the same navigation as the list!
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
    @Binding var friend: Friend
    @State private var showPaymentSheet = false
    @State private var paymentAmountString = ""
    
    var body: some View {
        VStack {
            VStack(spacing: 5) {
                Text("Total Outstanding").font(.subheadline).foregroundStyle(.secondary)
                Text("₹ \(Int(friend.totalOwed))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(friend.totalOwed > 0 ? .red : .green)
            }
            .padding(.vertical, 30)
            
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
            }
            .listStyle(.insetGrouped)
            
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
        .sheet(isPresented: $showPaymentSheet) {
            VStack(spacing: 20) {
                Text("Payment from \(friend.name)").font(.headline).padding(.top)
                TextField("Amount", text: $paymentAmountString)
                    .keyboardType(.decimalPad).font(.title.bold()).multilineTextAlignment(.center).padding()
                    .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
                
                Button(action: savePayment) {
                    Text("Confirm Payment").fontWeight(.bold).frame(maxWidth: .infinity).padding()
                        .background(Color.green).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal).disabled(paymentAmountString.isEmpty)
                Spacer()
            }
            .presentationDetents([.height(300)])
        }
    }
    
    func savePayment() {
        guard let amount = Double(paymentAmountString) else { return }
        
        // 1. Create the history record
        let newTransaction = FriendTransaction(date: Date(), amount: amount, type: .payment, note: "Paid Back")
        
        // 2. Update the values
        friend.history.append(newTransaction)
        friend.totalOwed -= amount
        
        // 3. UI SYNC: This forces the UI to refresh immediately
        paymentAmountString = ""
        showPaymentSheet = false
    }
}
