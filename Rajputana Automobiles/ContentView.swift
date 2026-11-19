import SwiftUI

struct ContentView: View {
    @State private var sessionManager = SessionManager.shared

    var body: some View {
        Group {
            if let session = sessionManager.session {
                if session.isCustomer {
                    CustomerAppShell()
                } else {
                    MainAppShell()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: sessionManager.session)
    }
}

#Preview {
    ContentView()
}
