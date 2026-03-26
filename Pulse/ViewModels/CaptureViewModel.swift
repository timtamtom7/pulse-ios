import Foundation
import SwiftUI
import Photos
import AVFoundation

enum CaptureMode: String, CaseIterable {
    case photo
    case voice
    case journal

    var icon: String {
        switch self {
        case .photo: return "camera.fill"
        case .voice: return "waveform"
        case .journal: return "pencil.line"
        }
    }
}

@Observable
final class CaptureViewModel: @unchecked Sendable {
    var captureMode: CaptureMode = .journal
    var journalText = ""
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var isAnalyzing = false
    var analysisResult: (score: Double, tags: [EmotionTag])?
    var showAnalysisSheet = false
    var errorMessage: String?
    var capturedImage: UIImage?
    var transcription = ""

    // R2: Voice tone analysis
    var voiceToneResult: VoiceToneResult?

    // R2: Vision photo analysis
    var visionResult: PhotoVisionResult?

    private let database = DatabaseService.shared
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingURL: URL?

    func capturePhoto(_ image: UIImage) async {
        await MainActor.run {
            capturedImage = image
            isAnalyzing = true
            errorMessage = nil
        }

        // R2: Use Vision-enhanced photo analysis
        let (score, tags, vision) = await AnalysisService.shared.analyzePhotoWithVision(image)

        await MainActor.run {
            isAnalyzing = false
            analysisResult = (score, tags)
            visionResult = vision
            showAnalysisSheet = true
        }
    }

    func startRecording() async {
        let permission = await PermissionService.shared.requestMicrophonePermission()
        guard permission == .authorized else {
            await MainActor.run {
                errorMessage = "Microphone access denied. Please enable it in Settings → Privacy & Security → Microphone → Pulse."
            }
            return
        }

        let speechPermission = await PermissionService.shared.requestSpeechPermission()
        guard speechPermission == .authorized else {
            await MainActor.run {
                errorMessage = "Speech recognition denied. Please enable it in Settings → Privacy & Security → Speech Recognition → Pulse."
            }
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            let audioFilename = documentsPath.appendingPathComponent("voice_\(UUID().uuidString).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            recordingURL = audioFilename

            await MainActor.run {
                isRecording = true
                recordingDuration = 0
            }

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.recordingDuration += 1
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }

    func stopRecording() async {
        audioRecorder?.stop()
        audioRecorder = nil
        recordingTimer?.invalidate()
        recordingTimer = nil

        await MainActor.run {
            isRecording = false
            isAnalyzing = true
        }

        guard let url = recordingURL else { return }

        do {
            transcription = try await AnalysisService.shared.transcribeAudio(url: url)

            // R2: Analyze voice tone (pitch, pace, stress)
            let toneResult = await AnalysisService.shared.analyzeVoiceTone(audioURL: url)

            let textAnalysis = await AnalysisService.shared.analyzeText(transcription)

            // Combine text and tone analysis
            var combinedScore = textAnalysis.score * 0.7
            let toneStressAdjusted = toneResult.stressLevel * -0.3
            combinedScore += toneStressAdjusted

            var allTags = textAnalysis.tags
            allTags.append(contentsOf: toneResult.emotionalTags)

            await MainActor.run {
                isAnalyzing = false
                analysisResult = (combinedScore, allTags)
                voiceToneResult = toneResult
                showAnalysisSheet = true
            }
        } catch {
            await MainActor.run {
                isAnalyzing = false
                errorMessage = "Failed to transcribe recording: \(error.localizedDescription)"
            }
        }
    }

    func submitJournal() async {
        guard !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
        }

        let analysis = await AnalysisService.shared.analyzeText(journalText)

        await MainActor.run {
            isAnalyzing = false
            analysisResult = analysis
            showAnalysisSheet = true
        }
    }

    func saveMoment(note: String?) {
        var content: String
        var momentType: MomentType

        switch captureMode {
        case .photo:
            if let image = capturedImage, let data = image.jpegData(compressionQuality: 0.8) {
                content = data.base64EncodedString()
            } else {
                content = ""
            }
            momentType = .photo
        case .voice:
            content = transcription
            momentType = .voice
        case .journal:
            content = journalText
            momentType = .journal
        }

        let moment = Moment(
            type: momentType,
            content: content,
            emotionScore: analysisResult?.score ?? 0,
            emotionTags: analysisResult?.tags ?? [],
            note: note
        )

        try? database.insertMoment(moment)
        reset()
    }

    func reset() {
        journalText = ""
        capturedImage = nil
        transcription = ""
        analysisResult = nil
        showAnalysisSheet = false
        errorMessage = nil
        voiceToneResult = nil
        visionResult = nil
    }

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var canSave: Bool {
        switch captureMode {
        case .photo: return capturedImage != nil
        case .voice: return !transcription.isEmpty || recordingDuration > 0
        case .journal: return !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
