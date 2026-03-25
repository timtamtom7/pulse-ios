import Foundation
import Photos
import EventKit
import Speech
import AVFoundation
import UIKit

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
}

@Observable
final class PermissionService: @unchecked Sendable {
    static let shared = PermissionService()

    var photosStatus: PermissionStatus = .notDetermined
    var calendarStatus: PermissionStatus = .notDetermined
    var speechStatus: PermissionStatus = .notDetermined
    var microphoneStatus: PermissionStatus = .notDetermined

    private let eventStore = EventKitService.shared.eventStore

    private init() {
        checkAllPermissions()
    }

    func checkAllPermissions() {
        checkPhotosPermission()
        checkCalendarPermission()
        checkSpeechPermission()
        checkMicrophonePermission()
    }

    // MARK: - Photos

    func checkPhotosPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photosStatus = mapPhotosStatus(status)
    }

    func requestPhotosPermission() async -> PermissionStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            photosStatus = mapPhotosStatus(status)
        }
        return photosStatus
    }

    private func mapPhotosStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    // MARK: - Calendar

    func checkCalendarPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        calendarStatus = mapCalendarStatus(status)
    }

    func requestCalendarPermission() async -> PermissionStatus {
        do {
            if #available(iOS 26.0, *) {
                let status = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    calendarStatus = status ? .authorized : .denied
                }
                return calendarStatus
            } else {
                let status = try await eventStore.requestAccess(to: .event)
                await MainActor.run {
                    calendarStatus = status ? .authorized : .denied
                }
                return calendarStatus
            }
        } catch {
            await MainActor.run {
                calendarStatus = .denied
            }
            return .denied
        }
    }

    private func mapCalendarStatus(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .fullAccess: return .authorized
        case .denied, .writeOnly: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    // MARK: - Speech

    func checkSpeechPermission() {
        let status = SFSpeechRecognizer.authorizationStatus()
        speechStatus = mapSpeechStatus(status)
    }

    func requestSpeechPermission() async -> PermissionStatus {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        await MainActor.run {
            speechStatus = mapSpeechStatus(status)
        }
        return speechStatus
    }

    private func mapSpeechStatus(_ status: SFSpeechRecognizerAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }

    // MARK: - Microphone

    func checkMicrophonePermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: microphoneStatus = .authorized
        case .denied: microphoneStatus = .denied
        case .undetermined: microphoneStatus = .notDetermined
        @unknown default: microphoneStatus = .notDetermined
        }
    }

    func requestMicrophonePermission() async -> PermissionStatus {
        let granted = await AVAudioApplication.requestRecordPermission()
        await MainActor.run {
            microphoneStatus = granted ? .authorized : .denied
        }
        return microphoneStatus
    }

    // MARK: - Helpers

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
