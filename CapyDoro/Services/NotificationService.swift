//
//  NotificationService.swift
//  CapyDoro
//
//  Shows the "phase finished" alert using macOS notifications (UserNotifications).
//  The alert is silent on purpose: SoundService plays the chime, so there's only one sound.
//

import Foundation
import os
import UserNotifications

// NSObject is needed because the notification delegate protocol comes from Objective-C.
final class NotificationService: NSObject, NotificationScheduling, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    /// One fixed ID: scheduling again replaces the old alert, cancelling removes it.
    private let requestID = "phase-end"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CapyDoro",
                                category: "notifications")

    override init() {
        super.init()
        center.delegate = self
    }

    /// Shows the "Allow notifications?" prompt the first time only.
    func requestAuthorizationIfNeeded() {
        // `Task { }` runs async code; `await` waits for macOS to answer without freezing the UI.
        Task {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .notDetermined else { return }
            do {
                let granted = try await center.requestAuthorization(options: [.alert])
                logger.info("Notification permission granted: \(granted)")
            } catch {
                // Denied or failed: the timer and chime still work, just without banners.
                logger.error("Notification permission request failed: \(error.localizedDescription)")
            }
        }
    }

    func scheduleEndOfPhase(_ phase: Phase, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = NotificationText.title(forEndOf: phase)
        content.body = NotificationText.body(forEndOf: phase)
        content.sound = nil

        // The trigger needs a delay of at least a moment, so never pass zero or less.
        let delay = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

        Task {
            do {
                try await center.add(request)
            } catch {
                logger.error("Could not schedule notification: \(error.localizedDescription)")
            }
        }
    }

    func cancelPending() {
        center.removePendingNotificationRequests(withIdentifiers: [requestID])
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Without this, macOS hides alerts from an app it considers "in front".
    /// `nonisolated`: macOS calls this from a background thread, not the main one.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
