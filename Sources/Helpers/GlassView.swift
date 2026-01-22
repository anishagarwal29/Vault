import SwiftUI
import AppKit

struct GlassView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material 
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

extension View {
    func glassBackground(material: NSVisualEffectView.Material = .hudWindow, 
                         blendingMode: NSVisualEffectView.BlendingMode = .withinWindow) -> some View {
        self.background(
            GlassView(material: material, blendingMode: blendingMode)
        )
    }
}
