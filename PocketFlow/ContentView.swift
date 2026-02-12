import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            DashboardView()
                .tabItem {
                    Label("Contri", systemImage: "person.2.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - Placeholder Views
struct HomeView: View {
    @State private var balance: Double = 2350.0
    @State private var inputAmount: String = ""
    @State private var isCredit: Bool = false // false = Spend (Default)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 1. The Balance Pill (Retained from previous plan)
                VStack {
                    Text("Available Balance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("₹ \(Int(balance))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                }
                .padding(.vertical, 25)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
                .padding(.horizontal)

                // 2. Your Drawing: Input Box + S/C Toggle
                HStack(spacing: 15) {
                    // Custom Amount Textbox
                    TextField("0", text: $inputAmount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    // The S | C Toggle (Segmented Picker style)
                    Picker("Transaction Type", selection: $isCredit) {
                        Text("Spend").tag(false)
                        Text("Credit").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    .scaleEffect(1.2) // Making it easier to tap
                }
                .padding(.horizontal)

                // 3. The "Save" Button (Crucial for Haste mode)
                Button(action: {
                    // We will add the SwiftData logic here in the next phase
                    inputAmount = ""
                }) {
                    Text("Log Transaction")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCredit ? Color.green : Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .padding(.horizontal)
                .disabled(inputAmount.isEmpty) // Prevent empty logs

                Spacer()
            }
            .navigationTitle("SwiftBalance")
            .padding(.top)
        }
    }
}

import SwiftUI

struct HistoryView: View {
    // 1. Using real Date objects now to test the logic
    @State private var mockHistory = [
        (amount: 50.0, date: Date(), detail: "", isCredit: false), // Today
        (amount: 1000.0, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, detail: "Pocket Money", isCredit: true), // Yesterday
        (amount: 120.0, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, detail: "Lunch", isCredit: false) // 2 Days ago
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(mockHistory.indices, id: \.self) { index in
                    HStack {
                        // Icon
                        Image(systemName: mockHistory[index].isCredit ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(mockHistory[index].isCredit ? .green : .red)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Amount
                            Text("₹ \(Int(mockHistory[index].amount))")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            // Haste-Log Logic
                            if mockHistory[index].detail.isEmpty {
                                Text("Tap to add details...")
                                    .font(.caption)
                                    .italic()
                                    .foregroundStyle(.orange)
                            } else {
                                Text(mockHistory[index].detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // 2. The Smart Date + Time Display
                        Text(formatDate(mockHistory[index].date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("History")
            .listStyle(.insetGrouped) // Cleaner iOS look
        }
    }
    
    // 3. The Logic Helper
    // This respects the user's 12h/24h setting automatically!
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        // Formatter for the TIME part (respects user settings)
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short // "10:30 PM" or "22:30" based on settings
        let timeString = timeFormatter.string(from: date)
        
        if calendar.isDateInToday(date) {
            return "Today, \(timeString)"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(timeString)"
        } else {
            // For older dates: "Tue, 10:30 PM"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E" // Short day name (Mon, Tue)
            let dayString = dateFormatter.string(from: date)
            return "\(dayString), \(timeString)"
        }
    }
}

#Preview {
    HistoryView()
}


import SwiftUI
import Charts

struct DashboardView: View {
    // 1. Mock Data for Charts
    let spendingData = [
        (category: "Food", amount: 1200, color: Color.orange),
        (category: "Travel", amount: 450, color: Color.blue),
        (category: "Entmt", amount: 300, color: Color.purple)
    ]
    
    // 2. Mock Data for "Wall of Debt" (Contri)
    @State private var peopleWhoOweMe = [
        (name: "Aditya", amount: 300),
        (name: "Rahul", amount: 150),
        (name: "Sneha", amount: 50)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // SECTION 1: SOCIAL LEDGER (Priority)
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Who Owes You")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: ContriDetailView()) {
                                Text("See All")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Horizontal Scroll of Debtors (Bento Style)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                // The "Add New" Card
                                Button(action: {}) {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title)
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: 60, height: 80)
                                    .background(Color.blue.opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                // The People Cards
                                ForEach(peopleWhoOweMe, id: \.name) { person in
                                    VStack(alignment: .leading) {
                                        Text(person.name)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text("₹\(person.amount)")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }
                                    .padding(12)
                                    .frame(width: 100, height: 80, alignment: .leading)
                                    .background(Color.black.opacity(0.8)) // Sleek dark cards
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // SECTION 2: SPENDING CHARTS (Visuals)
                    VStack(alignment: .leading) {
                        Text("Where your money went")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(spendingData, id: \.category) { item in
                            BarMark(
                                x: .value("Category", item.category),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(item.color)
                            .cornerRadius(5)
                        }
                        .frame(height: 200)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 5)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
        }
    }
}

// Keep the Detail View for when they click "See All"
struct ContriDetailView: View {
    var body: some View {
        Text("Full Contact List Goes Here")
    }
}

#Preview {
    ContentView()
}
