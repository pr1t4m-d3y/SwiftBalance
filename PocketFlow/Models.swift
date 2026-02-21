//import SwiftUI
//import Observation
//
//// MARK: - 1. TRANSACTION MODEL
//struct Transaction: Identifiable {
//    let id = UUID()
//    var category: String
//    var amount: Double
//    var date: Date
//    var isCredit: Bool // True = Money In (Green), False = Money Out (Red)
//    
//    // Color is computed automatically based on the category you provide
//    var color: Color {
//        if isCredit { return .green }
//        switch category {
//            case "Food": return .orange
//            case "Travel": return .blue
//            case "Entmt": return .purple
//            case "Groceries": return .green
//            case "Contri": return .pink
//            default: return .gray
//        }
//    }
//}
//
//// MARK: - 2. FRIEND MODELS (For the Social Ledger)
//struct Friend: Identifiable, Hashable {
//    let id = UUID()
//    let name: String
//    var totalOwed: Double
//    let color: Color
//    var history: [FriendTransaction]
//    
//    func hash(into hasher: inout Hasher) { hasher.combine(id) }
//}
//
//struct FriendTransaction: Identifiable, Hashable {
//    let id = UUID()
//    let date: Date
//    let amount: Double
//    let type: TransactionType
//    let note: String
//    
//    enum TransactionType { case debt, payment }
//}
//
//// MARK: - 3. THE SHARED BRAIN (AppDataStore)
//@Observable
//class AppDataStore {
//    // These lists hold all the data for your whole app
//    var transactions: [Transaction] = [
//        Transaction(category: "Food", amount: 150, date: Date(), isCredit: false),
//        Transaction(category: "Travel", amount: 450, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, isCredit: false)
//    ]
//    
//    var friends: [Friend] = [
//        Friend(name: "Aditya", totalOwed: 300, color: .orange, history: [
//            FriendTransaction(date: Date(), amount: 300, type: .debt, note: "Lunch Bill")
//        ]),
//        Friend(name: "Rahul", totalOwed: 500, color: .blue, history: [
//            FriendTransaction(date: Date(), amount: 500, type: .debt, note: "Concert Ticket")
//        ])
//    ]
//    
//    // --- CALCULATED LOGIC ---
//    
//    // Total Balance = Income - Expenses
//    // Using 0.0 explicitly fixes the 'Duration' to 'Double' error
//    var totalBalance: Double {
//        let income = transactions.filter { $0.isCredit }.reduce(0.0) { $0 + $1.amount }
//        let expense = transactions.filter { !$0.isCredit }.reduce(0.0) { $0 + $1.amount }
//        return income - expense
//    }
//    
//    // Sum of all money owed to you by friends
//    var totalContriAmount: Double {
//        friends.reduce(0.0) { $0 + $1.totalOwed }
//    }
//    
//    // --- ACTIONS ---
//    
//    func addTransaction(_ tx: Transaction) {
//        transactions.append(tx)
//    }
//}


import SwiftUI
import Observation

// MARK: - 1. TRANSACTION MODEL
struct Transaction: Identifiable {
    let id = UUID()
    var category: String
    var amount: Double
    var date: Date
    var isCredit: Bool
    
    // Phase 3: Description Tracking
    var note: String = ""
    var isDescriptionPending: Bool { note.isEmpty }
    
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

// MARK: - 2. FRIEND MODELS
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
    
    var totalBalance: Double {
        let income = transactions.filter { $0.isCredit }.reduce(0.0) { $0 + $1.amount }
        let expense = transactions.filter { !$0.isCredit }.reduce(0.0) { $0 + $1.amount }
        return income - expense
    }
    
    var totalContriAmount: Double {
        friends.reduce(0.0) { $0 + $1.totalOwed }
    }
    
    func addTransaction(_ tx: Transaction) {
        transactions.append(tx)
    }
    
    // Phase 3: Update existing transactions
    func updateTransaction(id: UUID, category: String, note: String) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index].category = category
            transactions[index].note = note
        }
    }
    
    // Phase 3: Add new debt dynamically
    func addFriendDebt(name: String, amount: Double, date: Date, note: String) {
        if amount <= 0 || name.trimmingCharacters(in: .whitespaces).isEmpty { return }
        
        let newDebt = FriendTransaction(date: date, amount: amount, type: .debt, note: note)
        
        if let index = friends.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            friends[index].history.append(newDebt)
            friends[index].totalOwed += amount
        } else {
            let colors: [Color] = [.orange, .blue, .purple, .pink, .green]
            let newFriend = Friend(name: name, totalOwed: amount, color: colors.randomElement()!, history: [newDebt])
            friends.append(newFriend)
        }
    }
}
