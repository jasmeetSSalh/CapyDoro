//
//  LaunchAtLoginService.swift
//  CapyDoro
//
//  Turns "open CapyDoro when I log in" on or off. macOS remembers this itself
//  (System Settings → General → Login Items), so we ask it instead of saving our own copy.
//

import ServiceManagement

final class LaunchAtLoginService {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// macOS sometimes wants the user to approve the login item in System Settings first.
    var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// `throws`: this can fail, and the caller must handle it with `try`.
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
