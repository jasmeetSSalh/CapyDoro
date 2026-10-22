//
//  SettingsView.swift
//  CapyDoro
//
//  The Settings window. Every control edits SettingsStore directly, so changes are
//  saved instantly; there's no Save button.
//

import SwiftUI

struct SettingsView: View {
    // @Bindable lets controls write back into an @Observable object via `$settings.…`.
    @Bindable var settings: SettingsStore
    let launchAtLogin: LaunchAtLoginService

    @State private var launchAtLoginOn = false
    @State private var launchError: String?

    var body: some View {
        Form {
            Section {
                minutesStepper("Focus", value: $settings.focusMinutes, range: SettingsStore.focusRange)
                minutesStepper("Short break", value: $settings.shortBreakMinutes, range: SettingsStore.breakRange)
                minutesStepper("Long break", value: $settings.longBreakMinutes, range: SettingsStore.breakRange)
                Stepper(value: $settings.sessionsBeforeLongBreak, in: SettingsStore.sessionsRange) {
                    LabeledContent("Long break after", value: "\(settings.sessionsBeforeLongBreak) focus sessions")
                }
            } header: {
                Text("Timer")
            } footer: {
                Text("Changes apply from the next phase.")
                    .foregroundStyle(.secondary)
            }

            Section("Behaviour") {
                Toggle("Play chime when a phase ends", isOn: $settings.soundEnabled)
                Toggle("Start the next phase automatically", isOn: $settings.autoStartNext)
            }

            Section("System") {
                Toggle("Open CapyDoro at login", isOn: $launchAtLoginOn)
                    .onChange(of: launchAtLoginOn) { _, newValue in
                        updateLaunchAtLogin(newValue)
                    }
                if launchAtLogin.needsApproval {
                    Button("Approve in System Settings…") {
                        launchAtLogin.openLoginItemsSettings()
                    }
                }
                if let launchError {
                    Text(launchError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            // Read the real state from macOS each time the window opens.
            launchAtLoginOn = launchAtLogin.isEnabled
        }
    }

    private func minutesStepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            LabeledContent(title, value: "\(value.wrappedValue) min")
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        // Only act on a real change, not on the window opening.
        guard enabled != launchAtLogin.isEnabled else { return }
        do {
            try launchAtLogin.setEnabled(enabled)
            launchError = nil
        } catch {
            launchError = "Couldn't change this: \(error.localizedDescription)"
            launchAtLoginOn = launchAtLogin.isEnabled   // put the switch back
        }
    }
}
