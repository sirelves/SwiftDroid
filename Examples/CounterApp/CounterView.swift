// Shared by the headless demo (core) and the iOS host (SwiftUI via SwiftDroidiOS).
#if SWIFTDROID_SWIFTUI
import SwiftDroidiOS
#else
import SwiftDroid
#endif

struct CounterApp: View {
    @State var count = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("Count: \(count)")
                .font(.largeTitle)
                .bold()
            Button("Increment") { count += 1 }
                .padding(.horizontal, 24)
                .foregroundColor(.blue)
        }
    }
}
