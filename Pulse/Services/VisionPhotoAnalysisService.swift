import Foundation
import Vision
import UIKit

struct PhotoVisionResult: Sendable {
    let detectedFaces: Int
    let sceneType: SceneType
    let dominantColors: [String]
    let brightness: Double
    let hasPeople: Bool
    let hasNature: Bool
    let hasCityscape: Bool

    enum SceneType: String, Sendable {
        case nature
        case city
        case indoor
        case people
        case food
        case abstract
        case unknown

        var emotionalTone: Double {
            switch self {
            case .nature: return 0.5
            case .food: return 0.4
            case .people: return 0.3
            case .city: return 0.1
            case .indoor: return 0.0
            case .abstract: return 0.0
            case .unknown: return 0.0
            }
        }

        var label: String {
            rawValue.capitalized
        }
    }
}

actor VisionPhotoAnalysisService {
    static let shared = VisionPhotoAnalysisService()

    private init() {}

    func analyzePhoto(_ image: UIImage) async -> PhotoVisionResult {
        guard let cgImage = image.cgImage else {
            return PhotoVisionResult(
                detectedFaces: 0,
                sceneType: .unknown,
                dominantColors: [],
                brightness: 0.5,
                hasPeople: false,
                hasNature: false,
                hasCityscape: false
            )
        }

        async let facesResult: Int = detectFaces(in: cgImage)
        async let classificationResult: [String] = classifyScene(cgImage)
        async let colorsResult: [String] = extractDominantColors(from: image)
        async let brightnessResult: Double = computeBrightness(from: cgImage)

        let (faces, classification, colors, brightness) = await (facesResult, classificationResult, colorsResult, brightnessResult)

        let hasPeople = faces > 0
        let hasNature = classification.contains("nature") || classification.contains("outdoor")
        let hasCityscape = classification.contains("city") || classification.contains("urban")

        let sceneType = determineSceneType(
            classification: classification,
            hasPeople: hasPeople,
            hasNature: hasNature,
            hasCityscape: hasCityscape
        )

        return PhotoVisionResult(
            detectedFaces: faces,
            sceneType: sceneType,
            dominantColors: colors,
            brightness: brightness,
            hasPeople: hasPeople,
            hasNature: hasNature,
            hasCityscape: hasCityscape
        )
    }

    private func detectFaces(in image: CGImage) async -> Int {
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                let count = (request.results as? [VNFaceObservation])?.count ?? 0
                continuation.resume(returning: count)
            }
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    private func classifyScene(_ image: CGImage) async -> [String] {
        return await withCheckedContinuation { continuation in
            guard #available(iOS 18.0, *) else {
                continuation.resume(returning: ["unknown"])
                return
            }

            let request = VNClassifyImageRequest { request, error in
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: ["unknown"])
                    return
                }

                let topResults = results
                    .filter { $0.confidence > 0.1 }
                    .prefix(5)
                    .map { $0.identifier.lowercased() }

                continuation.resume(returning: Array(topResults))
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    private func extractDominantColors(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        let width = min(cgImage.width, 50)
        let height = min(cgImage.height, 50)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return [] }

        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var colorCounts: [String: Int] = [:]

        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                let offset = (y * width + x) * 4
                let r = Int(pointer[offset]) / 32
                let g = Int(pointer[offset + 1]) / 32
                let b = Int(pointer[offset + 2]) / 32

                let colorKey = "\(r),\(g),\(b)"

                if colorKey != "7,7,7" {
                    colorCounts[colorKey, default: 0] += 1
                }
            }
        }

        let sortedColors = colorCounts.sorted { $0.value > $1.value }.prefix(3)

        return sortedColors.map { colorKey in
            let components = colorKey.key.split(separator: ",").compactMap { Int($0) }
            if components.count == 3 {
                let r = components[0] * 32 + 16
                let g = components[1] * 32 + 16
                let b = components[2] * 32 + 16
                return String(format: "#%02X%02X%02X", r, g, b)
            }
            return "#000000"
        }
    }

    private func computeBrightness(from image: CGImage) async -> Double {
        let width = min(image.width, 50)
        let height = min(image.height, 50)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0.5 }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 0.5 }

        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var totalBrightness: Double = 0
        let sampleCount = width * height

        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let offset = (y * width + x) * 4
                let r = Double(pointer[offset]) / 255.0
                let g = Double(pointer[offset + 1]) / 255.0
                let b = Double(pointer[offset + 2]) / 255.0
                totalBrightness += (r * 0.299 + g * 0.587 + b * 0.114)
            }
        }

        return totalBrightness / Double(sampleCount / 4)
    }

    private func determineSceneType(
        classification: [String],
        hasPeople: Bool,
        hasNature: Bool,
        hasCityscape: Bool
    ) -> PhotoVisionResult.SceneType {
        if hasPeople {
            return .people
        }

        if hasNature {
            return .nature
        }

        if hasCityscape {
            return .city
        }

        let classString = classification.joined(separator: " ")

        if classString.contains("indoor") || classString.contains("home") || classString.contains("room") {
            return .indoor
        }

        if classString.contains("food") || classString.contains("drink") || classString.contains("meal") {
            return .food
        }

        if classString.contains("abstract") || classString.contains("art") || classString.contains("design") {
            return .abstract
        }

        return .unknown
    }
}
