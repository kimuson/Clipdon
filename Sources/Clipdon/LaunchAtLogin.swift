import ServiceManagement
import AppKit

/// Wraps `SMAppService` so the user can toggle "launch at login" from the popup.
///
/// This only takes effect when Clipdon runs as a real `.app` bundle
/// (e.g. built with `build-app.sh`), not as a bare `swift run` executable —
/// a bare binary has no bundle identifier for the system to register.
enum LaunchAtLogin {
    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// True when running inside a proper app bundle, where the toggle works.
    static var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    /// Registers or unregisters the app as a login item.
    static func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
        } catch {
            NSLog("[Clipdon] launch-at-login \(enabled ? "register" : "unregister") failed: \(error.localizedDescription)")
            // If the user previously disabled it in System Settings, the API
            // can't re-enable silently — send them to the right pane.
            if service.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        }
    }
}
