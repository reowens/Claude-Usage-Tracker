//
//  View+GlassEffect.swift
//  Claude Usage Widget
//
//  Liquid Glass card background for widget views (macOS 26+)
//

import SwiftUI

extension View {
    /// Applies Liquid Glass card background to a widget card/tile.
    /// Replaces the manual Color.white.opacity(0.05) + cornerRadius pattern.
    func widgetCardBackground() -> some View {
        self.glassEffect(.regular, in: .rect(cornerRadius: WidgetDesign.Spacing.cardCornerRadius))
    }
}
