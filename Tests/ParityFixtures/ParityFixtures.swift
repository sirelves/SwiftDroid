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

struct ParityModifiers: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("a").padding()
            Text("b").padding(8)
            Text("c").padding(.horizontal, 12)
            Text("d").padding(EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4))
            Text("e").frame(width: 100, height: 40, alignment: .topLeading)
            Text("f").frame(height: 30).padding(.top)
            EmptyView().padding().frame(width: 50)
            Text("g").frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ParityStyles: View {
    var body: some View {
        VStack {
            Text("title").font(.title)
            Text("headline").font(.headline).foregroundColor(.secondary)
            Text("custom").font(.system(size: 20, weight: .semibold))
            Text("weights").fontWeight(.light)
            Text("bold font").font(.body.bold())
            Text("rgb").foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6, opacity: 0.8))
            Text("faded").foregroundColor(.blue.opacity(0.5))
            Group {
                Text("g1")
                Text("g2").bold(false)
            }
            .bold()
            Button("styled") {}.font(.caption).foregroundColor(.red)
        }
        .font(.callout)
        .foregroundColor(.primary)
    }
}

struct ParityTodo: Identifiable {
    let id: Int
    var title: String
}

final class ParityTodoList: ObservableObject {
    @Published var todos = [ParityTodo(id: 1, title: "milk"), ParityTodo(id: 2, title: "eggs")]
}

struct ParityTodoRow: View {
    let todo: ParityTodo
    @State var done = false

    var body: some View {
        Button("\(done ? "✓" : "○") \(todo.title)") { done.toggle() }
    }
}

struct ParityLists: View {
    @ObservedObject var list: ParityTodoList
    let tags = ["a", "b"]

    var body: some View {
        VStack {
            ForEach(list.todos) { ParityTodoRow(todo: $0) }
            ForEach(tags, id: \.self) { Text($0) }
            ForEach(0..<2) { Text("#\($0)") }
            Button("reverse") { list.todos.reverse() }
        }
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
