// iOS probe for ListMetrics: renders one List case (MODE env var), prints each
// reported frame as "PROBE <mode> <name> x= y= w= h=" and exits.
// Run with scripts/measure-ios-list.sh.
import SwiftUI

struct FrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue()) { $1 } }
}
extension View {
    func report(_ name: String) -> some View {
        background(GeometryReader { g in Color.clear.preference(key: FrameKey.self, value: [name: g.frame(in: .global)]) })
    }
}
func fmt(_ r: CGRect) -> String { "x=\(r.minX) y=\(r.minY) w=\(r.width) h=\(r.height)" }

struct Probe: View {
    let mode: String
    @State var done = false
    var body: some View {
        Group {
            switch mode {
            case "plainDefault":
                List { ForEach(0..<3) { Text("Row \($0)").report("row\($0)") } }.report("list")
            case "sections":
                List {
                    Section("First") { Text("A").report("a"); Text("B").report("b") }
                    Section { Text("C").report("c") } header: { Text("Second").report("hdr2") } footer: { Text("foot").report("foot") }
                }.report("list")
            case "tall":
                List { Text("x").frame(height: 80).report("tallrow"); Text("y").report("short") }.report("list")
            case "styledPlain":
                List { ForEach(0..<2) { Text("Row \($0)").report("row\($0)") } }.listStyle(.plain).report("list")
            case "hdrFirst":
                List {
                    Section { Text("A").report("a") } header: { Text("Head1").report("h1") } footer: { Text("Foot1").report("f1") }
                    Section { Text("B").report("b") } header: { Text("Head2").report("h2") }
                    Section { Text("C").report("c") }
                }.report("list")
            case "plainSections":
                List {
                    Section { Text("A").report("a"); Text("A2").report("a2") } header: { Text("Head1").report("h1") } footer: { Text("Foot1").report("f1") }
                    Section { Text("B").report("b") } header: { Text("Head2").report("h2") }
                }.listStyle(.plain).report("list")
            case "rowKinds":
                List {
                    Button("Tap") {}.report("button")
                    HStack { Text("L").report("hl"); Spacer(); Text("R").report("hr") }.report("hstack")
                    Text("multi\nline").report("multi")
                    Text("cap").font(.caption).report("caption")
                }.report("list")
            default:
                VStack { Text("Row").report("bare"); Divider().report("divider") }.report("vstack")
            }
        }
        .onPreferenceChange(FrameKey.self) { frames in
            guard !done, frames.count > 1 else { return }
            done = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                for (k, v) in frames.sorted(by: { $0.key < $1.key }) { print("PROBE \(mode) \(k) \(fmt(v))") }
                exit(0)
            }
        }
    }
}

@main struct ProbeApp: App {
    var body: some Scene {
        WindowGroup { Probe(mode: ProcessInfo.processInfo.environment["MODE"] ?? "plainDefault") }
    }
}
