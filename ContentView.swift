import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button("OK") {
                print("OK button tapped")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ContentView()
}
