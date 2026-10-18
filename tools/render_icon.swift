import SwiftUI
import AppKit

// Renders the real orb shader into a 1024x1024 app icon.
let library = ShaderLibrary(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let time = Double(CommandLine.arguments[3]) ?? 12

let canvas = Color(red: 0.035, green: 0.039, blue: 0.063)
let core = Color(red: 1.00, green: 0.88, blue: 0.68)
let mid = Color(red: 0.98, green: 0.46, blue: 0.33)
let rim = Color(red: 0.42, green: 0.22, blue: 0.76)

struct Icon: View {
    var body: some View {
        ZStack {
            canvas
            RadialGradient(colors: [rim.opacity(0.55), .clear], center: UnitPoint(x: 0.15, y: 0.1), startRadius: 0, endRadius: 900)
            RadialGradient(colors: [mid.opacity(0.18), .clear], center: UnitPoint(x: 0.9, y: 0.95), startRadius: 0, endRadius: 700)
            Rectangle()
                .fill(library.orb(.boundingRect, .float(time), .float(0.32), .float(0.18), .color(core), .color(mid), .color(rim)))
                .padding(40)
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor func render() {
    let renderer = ImageRenderer(content: Icon())
    renderer.scale = 1
    guard let image = renderer.cgImage else { print("render failed"); return }
    let rep = NSBitmapImageRep(cgImage: image)
    let data = rep.representation(using: .png, properties: [:])
    try? data?.write(to: output)
    print("ok")
}
MainActor.assumeIsolated { render() }
