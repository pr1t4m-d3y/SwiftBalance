import SwiftUI

@main
struct PocketFlowApp: App {
    // This creates the data when the app starts
    @State private var store = AppDataStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store) // This shares the data with EVERY screen
        }
    }
}

