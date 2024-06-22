import SwiftUI

struct ContentView: View {
    // This is a simple placeholder view for now,
    // since the main functionality is handled by the AppDelegate
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
