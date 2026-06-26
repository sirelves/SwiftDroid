import SwiftDroid

/// The canonical SwiftDroid demo: a counter built from `@State`, `Text`, `Button`
/// and `VStack` — the exact SwiftUI programming model, running on the platform-
/// agnostic core. On Android this same view drives Jetpack Compose; here it runs
/// headless so the full pipeline (reactivity → layout → render) is observable in
/// a terminal.
struct CounterApp: View {
    @State var count = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
}

@main
struct CounterAppDemo {
    static func main() {
        let host = ViewHost(
            CounterApp(),
            engine: .monospace(charWidth: 10, lineHeight: 20),
            proposal: ProposedSize(width: 320, height: 200)
        )

        print("SwiftDroid · CounterApp (headless demo)")
        print("Initial frame:")
        dumpFrame(host.commands)

        // Simulate three taps on the Increment button.
        for _ in 0..<3 {
            if let button = host.commands.first(where: { $0.kind == .button }) {
                host.tap(at: Point(
                    x: button.frame.x + button.frame.width / 2,
                    y: button.frame.y + button.frame.height / 2
                ))
            }
        }

        print("\nAfter 3 taps:")
        dumpFrame(host.commands)
    }

    private static func dumpFrame(_ commands: [DrawCommand]) {
        for command in commands {
            let f = command.frame
            let pos = "@ (\(f.x), \(f.y))  \(f.width)x\(f.height)"
            switch command.kind {
            case .text(let content): print("  text   \"\(content)\"  \(pos)")
            case .button:            print("  button  \(pos)")
            }
        }
    }
}
