import SwiftUI
import Observation

// MARK: - 1. TRANSACTION MODEL
struct Transaction: Identifiable {
    let id = UUID()
    var category: String
    var amount: Double
    var date: Date
    var isCredit: Bool // True = Money In (Green), False = Money Out (Red)
    
    // Color is computed automatically based on the category you provide
    var color: Color {
        if isCredit { return .green }
        switch category {
            case "Food": return .orange
            case "Travel": return .blue
            case "Entmt": return .purple
            case "Groceries": return .green
            case "Contri": return .pink
            default: return .gray
        }
    }
}

// MARK: - 2. FRIEND MODELS (For the Social Ledger)
struct Friend: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var totalOwed: Double
    let color: Color
    var history: [FriendTransaction]
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct FriendTransaction: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let amount: Double
    let type: TransactionType
    let note: String
    
    enum TransactionType { case debt, payment }
}

// MARK: - 3. THE SHARED BRAIN (AppDataStore)
@Observable
class AppDataStore {
    // These lists hold all the data for your whole app
    var transactions: [Transaction] = [
        Transaction(category: "Food", amount: 150, date: Date(), isCredit: false),
        Transaction(category: "Travel", amount: 450, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, isCredit: false)
    ]
    
    var friends: [Friend] = [
        Friend(name: "Aditya", totalOwed: 300, color: .orange, history: [
            FriendTransaction(date: Date(), amount: 300, type: .debt, note: "Lunch Bill")
        ]),
        Friend(name: "Rahul", totalOwed: 500, color: .blue, history: [
            FriendTransaction(date: Date(), amount: 500, type: .debt, note: "Concert Ticket")
        ])
    ]
    
    // --- CALCULATED LOGIC ---
    
    // Total Balance = Income - Expenses
    // Using 0.0 explicitly fixes the 'Duration' to 'Double' error
    var totalBalance: Double {
        let income = transactions.filter { $0.isCredit }.reduce(0.0) { $0 + $1.amount }
        let expense = transactions.filter { !$0.isCredit }.reduce(0.0) { $0 + $1.amount }
        return income - expense
    }
    
    // Sum of all money owed to you by friends
    var totalContriAmount: Double {
        friends.reduce(0.0) { $0 + $1.totalOwed }
    }
    
    // --- ACTIONS ---
    
    func addTransaction(_ tx: Transaction) {
        transactions.append(tx)
    }
}
