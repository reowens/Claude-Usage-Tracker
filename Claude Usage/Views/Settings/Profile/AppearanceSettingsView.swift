//
//  AppearanceSettingsView.swift
//  Claude Usage - Menu Bar Appearance Settings
//
//  Created by Claude Code on 2025-12-27.
//

import SwiftUI

/// Menu bar icon appearance global settings (monochrome, labels)
struct AppearanceSettingsView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var configuration: MenuBarIconConfiguration = .default

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                // Page Header
                SettingsPageHeader(
                    title: "appearance.title".localized,
                    subtitle: "appearance.subtitle".localized
                )

                // Global Settings
                SettingsSectionCard(
                    title: "appearance.global_settings".localized,
                    subtitle: "appearance.global_subtitle".localized
                ) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.cardPadding) {
                        SettingToggle(
                            title: "appearance.monochrome_title".localized,
                            description: "appearance.monochrome_description".localized,
                            isOn: Binding(
                                get: { configuration.monochromeMode },
                                set: { newValue in
                                    configuration.monochromeMode = newValue
                                    saveConfiguration()
                                }
                            )
                        )

                        SettingToggle(
                            title: "appearance.show_labels_title".localized,
                            description: "appearance.show_labels_description".localized,
                            isOn: Binding(
                                get: { configuration.showIconNames },
                                set: { newValue in
                                    configuration.showIconNames = newValue
                                    saveConfiguration()
                                }
                            )
                        )
                    }
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            // Load configuration from active profile
            if let activeProfile = profileManager.activeProfile {
                configuration = activeProfile.iconConfig
            }
        }
        .onChange(of: profileManager.activeProfile?.id) { _, newProfileId in
            // Reload configuration when profile changes
            if let activeProfile = profileManager.activeProfile {
                configuration = activeProfile.iconConfig
            }
        }
    }

    // MARK: - Helper Methods

    private func saveConfiguration() {
        // Save to active profile
        guard let profileId = profileManager.activeProfile?.id else {
            LoggingService.shared.logError("Cannot save appearance: no active profile")
            return
        }

        profileManager.updateIconConfig(configuration, for: profileId)

        // Notify that config changed (for MenuBarManager to update)
        NotificationCenter.default.post(name: .menuBarIconConfigChanged, object: nil)

        LoggingService.shared.log("Saved appearance configuration to profile")
    }
}

// MARK: - Previews

#Preview {
    AppearanceSettingsView()
        .frame(width: 520, height: 600)
}
