// Compiled against both backends (symlinked); a build error here = API divergence.

#if PARITY_SWIFTUI
#if canImport(SwiftUI)
import SwiftDroidiOS
#endif
#else
import SwiftDroid
#endif

#if !PARITY_SWIFTUI || canImport(SwiftUI)

struct ParityCounter: View {
    @State var count = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
}

struct ParityStacks: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                Text("left")
                Spacer()
                Text("right")
            }
            ZStack(alignment: .topTrailing) {
                Text("back")
                Text("front")
            }
            Spacer(minLength: 16)
            HStack { Text("defaults") }
            ZStack { EmptyView() }
        }
    }
}

struct ParityConditional: View {
    let flag: Bool

    var body: some View {
        VStack {
            if flag {
                Text("on")
            } else {
                Text("off")
            }
            if flag {
                Text("only when on")
            }
        }
    }
}

struct ParityToggleRow: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(isOn ? "ON" : "OFF")
        }
    }
}

struct ParityBindingParent: View {
    @State var isOn = false

    var body: some View {
        VStack {
            ParityToggleRow(isOn: $isOn)
            ParityToggleRow(isOn: .constant(true))
        }
    }
}

// No hand-written objectWillChange: Combine synthesises it, so the core must too.
final class ParityModel: ObservableObject {
    @Published var taps = 0
    @Published var name = "model"
}

struct ParityModelView: View {
    @ObservedObject var model: ParityModel

    var body: some View {
        VStack {
            Text("\(model.name): \(model.taps)")
            Button("Tap") { model.taps += 1 }
            ParityNameEditor(name: $model.name)
        }
    }
}

struct ParityNameEditor: View {
    @Binding var name: String

    var body: some View {
        Button("Rename") { name = "renamed" }
    }
}

struct ParityGroup: View {
    var body: some View {
        VStack {
            Group {
                Text("1"); Text("2"); Text("3"); Text("4"); Text("5")
                Text("6"); Text("7"); Text("8"); Text("9"); Text("10")
            }
            Text("11")
        }
    }
}

#endif
