import Foundation
import AVFoundation
import Speech

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
    var capturedImage: Any? = nil  // Use Any for macOS compatibility
    var transcription = ""

    private let database = DatabaseService.shared
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingURL: URL?

    func capturePhoto(_ image: Any) {
        // Simplified for macOS - photo capture is a placeholder
        capturedImage = image
        isAnalyzing = false
        // No real analysis on macOS without Vision framework
        showAnalysisSheet = true
    }

    func startRecording() async {
        let permission = await PermissionService.shared.requestMicrophonePermission()
        guard permission == .authorized else {
            await MainActor.run {
                errorMessage = "Microphone access denied. Please enable it in System Settings → Privacy & Security → Microphone."
            }
            return
        }

        let speechPermission = await PermissionService.shared.requestSpeechPermission()
        guard speechPermission == .authorized else {
            await MainActor.run {
                errorMessage = "Speech recognition denied. Please enable it in System Settings → Privacy & Security → Speech Recognition."
            }
            return
        }

        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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

            let toneResult = await AnalysisService.shared.analyzeVoiceTone(audioURL: url)
            let textAnalysis = await AnalysisService.shared.analyzeText(transcription)

            var combinedScore = textAnalysis.score * 0.7
            let toneStressAdjusted = toneResult.stressLevel * -0.3
            combinedScore += toneStressAdjusted

            var allTags = textAnalysis.tags
            allTags.append(contentsOf: toneResult.emotionalTags)

            await MainActor.run {
                isAnalyzing = false
                analysisResult = (combinedScore, allTags)
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
            content = "Photo captured"
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
