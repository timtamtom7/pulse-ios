import Foundation
import AVFoundation
import Speech

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

    private init() {
        checkAllPermissions()
    }

    func checkAllPermissions() {
        checkMicrophonePermission()
        checkSpeechPermission()
    }

    func checkMicrophonePermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        case .undetermined:
            microphoneStatus = .notDetermined
        @unknown default:
            microphoneStatus = .notDetermined
        }
    }

    func checkSpeechPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechStatus = .authorized
        case .denied:
            speechStatus = .denied
        case .restricted:
            speechStatus = .restricted
        case .notDetermined:
            speechStatus = .notDetermined
        @unknown default:
            speechStatus = .notDetermined
        }
    }

    func requestMicrophonePermission() async -> PermissionStatus {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphoneStatus = granted ? .authorized : .denied
                    continuation.resume(returning: granted ? .authorized : .denied)
                }
            }
        }
    }

    func requestSpeechPermission() async -> PermissionStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self.speechStatus = .authorized
                        continuation.resume(returning: .authorized)
                    case .denied:
                        self.speechStatus = .denied
                        continuation.resume(returning: .denied)
                    case .restricted:
                        self.speechStatus = .restricted
                        continuation.resume(returning: .restricted)
                    case .notDetermined:
                        self.speechStatus = .notDetermined
                        continuation.resume(returning: .notDetermined)
                    @unknown default:
                        self.speechStatus = .notDetermined
                        continuation.resume(returning: .notDetermined)
                    }
                }
            }
        }
    }

    func requestPhotosPermission() async -> PermissionStatus {
        // Photos library access is typically handled via NSOpenPanel on macOS
        return .notDetermined
    }

    func requestCalendarPermission() async -> PermissionStatus {
        return .notDetermined
    }
}
