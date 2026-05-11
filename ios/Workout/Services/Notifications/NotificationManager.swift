//
//  NotificationManager.swift
//  Workout
//
//  Created by Dexter Darwich on 2026-03-16.
//

import Foundation
import UserNotifications
import SwiftData

/// Manages workout reminder notifications.
/// Handles permission requests, scheduling daily reminders, and clearing notifications.
@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    private let reminderCategoryID = "WORKOUT_REMINDER"
    private let dailyReminderID = "daily_workout_reminder"
    private let restTimerID = "rest_timer_complete"
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Show notifications even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
    
    // MARK: - Authorization
    
    /// Checks the current notification authorization status.
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    /// Requests notification permissions from the user.
    /// Returns true if authorization was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
            await refreshAuthorizationStatus()
            return false
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedules a daily workout reminder at the specified time.
    /// Removes any existing reminder before scheduling.
    func scheduleDailyReminder(at time: Date) async {
        // Remove existing reminder first
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Work Out"
        content.body = reminderBody()
        content.sound = .default
        content.categoryIdentifier = reminderCategoryID
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: dailyReminderID,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification: \(error.localizedDescription)")
        }
    }
    
    /// Schedules a local notification for when the rest timer expires.
    /// Requests permission first if not yet determined. Replaces any existing rest timer notification.
    func scheduleRestTimer(endDate: Date) {
        Task {
            let status = await center.notificationSettings().authorizationStatus
            if status == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
            }
            guard await center.notificationSettings().authorizationStatus == .authorized else { return }

            center.removePendingNotificationRequests(withIdentifiers: [restTimerID])
            let seconds = endDate.timeIntervalSinceNow
            guard seconds > 0 else { return }

            let content = UNMutableNotificationContent()
            content.title = "Rest Over"
            content.body = "Time to hit the next set!"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            let request = UNNotificationRequest(identifier: restTimerID, content: content, trigger: trigger)
            try? await center.add(request)
            await refreshAuthorizationStatus()
        }
    }

    /// Cancels a pending rest timer notification (call on skip or in-app completion).
    func cancelRestTimer() {
        center.removePendingNotificationRequests(withIdentifiers: [restTimerID])
    }

    /// Cancels all scheduled workout reminders.
    func cancelAllReminders() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }
    
    /// Removes delivered notifications from the notification center.
    func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
    
    // MARK: - Helpers
    
    private func reminderBody() -> String {
        let messages = [
            "Your muscles are ready. Let's go!",
            "Consistency builds strength. Time to train.",
            "Don't skip today — future you will thank you.",
            "Rest day or training day? Check your recovery.",
            "Progress is made one workout at a time."
        ]
        return messages.randomElement() ?? messages[0]
    }
}
