//
//import SwiftUI
//import Observation
//
//// MARK: - 1. TRANSACTION MODEL
//struct Transaction: Identifiable {
//    let id = UUID()
//    var category: String
//    var amount: Double
//    var date: Date
//    var isCredit: Bool
//    
//    // Phase 3: Description Tracking
//    var note: String = ""
//    var isDescriptionPending: Bool { note.isEmpty }
//    
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
//// MARK: - 2. FRIEND MODELS
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
//    var totalBalance: Double {
//        let income = transactions.filter { $0.isCredit }.reduce(0.0) { $0 + $1.amount }
//        let expense = transactions.filter { !$0.isCredit }.reduce(0.0) { $0 + $1.amount }
//        return income - expense
//    }
//    
//    var totalContriAmount: Double {
//        friends.reduce(0.0) { $0 + $1.totalOwed }
//    }
//    
//    func addTransaction(_ tx: Transaction) {
//        transactions.append(tx)
//    }
//    
//    // Phase 3: Update existing transactions
//    func updateTransaction(id: UUID, category: String, note: String) {
//        if let index = transactions.firstIndex(where: { $0.id == id }) {
//            transactions[index].category = category
//            transactions[index].note = note
//        }
//    }
//    
//    // Phase 3: Add new debt dynamically
//    func addFriendDebt(name: String, amount: Double, date: Date, note: String) {
//        if amount <= 0 || name.trimmingCharacters(in: .whitespaces).isEmpty { return }
//        
//        let newDebt = FriendTransaction(date: date, amount: amount, type: .debt, note: note)
//        
//        if let index = friends.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
//            friends[index].history.append(newDebt)
//            friends[index].totalOwed += amount
//        } else {
//            let colors: [Color] = [.orange, .blue, .purple, .pink, .green]
//            let newFriend = Friend(name: name, totalOwed: amount, color: colors.randomElement()!, history: [newDebt])
//            friends.append(newFriend)
//        }
//    }
//}


import SwiftUI
import Observation
import Contacts
import UserNotifications

// MARK: - 1. SPLIT PERSON MODEL
struct SplitPerson: Identifiable {
    let id = UUID()
    var name: String = ""
    var phoneNumber: String? = nil
    var amount: Double = 0.0
    var isLocked: Bool = false
}

// MARK: - 2. TRANSACTION MODEL
struct Transaction: Identifiable {
    let id = UUID()
    var category: String
    var amount: Double
    var date: Date
    var isCredit: Bool
    
    var note: String = ""
    var notificationID: String? = nil
    var isDescriptionPending: Bool { note.isEmpty }
    var splits: [SplitPerson] = []
    
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

// MARK: - 3. FRIEND MODELS
struct Friend: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var totalOwed: Double
    let color: Color
    var history: [FriendTransaction]
    var phoneNumber: String? = nil
    
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

// MARK: - 4. THE SHARED BRAIN
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
    
    var totalContriAmount: Double { friends.reduce(0.0) { $0 + $1.totalOwed } }
    
    func addTransaction(_ tx: Transaction) { transactions.append(tx) }
    
    func updateTransaction(id: UUID, category: String, note: String, splits: [SplitPerson] = []) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index].category = category
            transactions[index].note = note
            transactions[index].splits = splits
        }
    }
    
    func addFriendDebt(name: String, phoneNumber: String?, amount: Double, date: Date, note: String) {
        if amount <= 0 || name.trimmingCharacters(in: .whitespaces).isEmpty { return }
        let newDebt = FriendTransaction(date: date, amount: amount, type: .debt, note: note)
        
        if let index = friends.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            friends[index].history.append(newDebt)
            friends[index].totalOwed += amount
            if friends[index].phoneNumber == nil { friends[index].phoneNumber = phoneNumber }
        } else {
            // FIX: Guaranteed distinct colors for the first 8 friends so the chart isn't all red
            let distinctColors: [Color] = [.orange, .blue, .purple, .pink, .teal, .indigo, .mint, .yellow]
            let colorToAssign = distinctColors[friends.count % distinctColors.count]
            
            let newFriend = Friend(name: name, totalOwed: amount, color: colorToAssign, history: [newDebt], phoneNumber: phoneNumber)
            friends.append(newFriend)
        }
    }
    
    func requestPermissions() {
        CNContactStore().requestAccess(for: .contacts) { _, _ in }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func searchContacts(query: String) -> [(name: String, phone: String?)] {
        guard !query.isEmpty else { return [] }
        let store = CNContactStore()
        var results: [(name: String, phone: String?)] = []
        let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor])
        
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                if fullName.lowercased().contains(query.lowercased()) {
                    let phone = contact.phoneNumbers.first?.value.stringValue
                    results.append((name: fullName, phone: phone))
                }
            }
        } catch { print("Contact search failed") }
        return Array(results.prefix(3))
    }
    
    func scheduleReminder(amount: Double) -> String {
        let content = UNMutableNotificationContent()
        content.title = "PocketFlow Reminder"
        content.body = "You have a ₹\(Int(amount)) expense waiting for a description!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
        let requestID = UUID().uuidString
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        return requestID
    }
    
    func cancelReminder(id: String?) {
        guard let id = id else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
