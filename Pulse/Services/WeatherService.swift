import Foundation
import CoreLocation

struct WeatherData: Codable, Sendable {
    let temperature: Double
    let condition: WeatherCondition
    let humidity: Double
    let uvIndex: Double
    let date: Date
    let location: String?

    enum WeatherCondition: String, Codable {
        case sunny
        case cloudy
        case rainy
        case snowy
        case stormy
        case windy
        case foggy
        case clear

        var emotionalInfluence: Double {
            switch self {
            case .sunny, .clear: return 0.4
            case .cloudy: return 0.0
            case .rainy: return -0.2
            case .snowy: return 0.1
            case .stormy: return -0.4
            case .windy: return -0.1
            case .foggy: return -0.1
            }
        }

        var label: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .sunny: return "sun.max.fill"
            case .clear: return "moon.stars.fill"
            case .cloudy: return "cloud.fill"
            case .rainy: return "cloud.rain.fill"
            case .snowy: return "cloud.snow.fill"
            case .stormy: return "cloud.bolt.rain.fill"
            case .windy: return "wind"
            case .foggy: return "cloud.fog.fill"
            }
        }
    }

    var emotionalTone: Double {
        var tone = condition.emotionalInfluence

        // Temperature: optimal around 20-22°C
        let optimalTemp = 21.0
        let tempDeviation = abs(temperature - optimalTemp)
        if tempDeviation > 10 {
            tone -= 0.1
        }

        // UV: moderate sun is positive, high UV is negative
        if uvIndex > 8 {
            tone -= 0.1
        } else if uvIndex > 3 && uvIndex < 8 {
            tone += 0.1
        }

        return max(-1, min(1, tone))
    }
}

@Observable
final class WeatherService: @unchecked Sendable {
    static let shared = WeatherService()

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    private init() {}

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func fetchWeather(for date: Date = Date()) async -> WeatherData? {
        // Try to get location
        let location = await getCurrentLocation()

        // Use wttr.in API (free, no key required)
        // For past dates, we synthesize weather from typical patterns
        // since wttr.in only provides current/future weather
        let locationString: String
        if let loc = location {
            locationString = "\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
        } else {
            locationString = "auto_detect"
        }

        guard let url = URL(string: "https://wttr.in/\(locationString)?format=j1") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let currentCondition = (json["current_condition"] as? [[String: Any]])?.first else {
                return nil
            }

            let tempC = Double(currentCondition["temp_C"] as? String ?? "20") ?? 20
            let humidity = Double(currentCondition["humidity"] as? String ?? "50") ?? 50
            let uvIndex = Double(currentCondition["uvIndex"] as? String ?? "5") ?? 5
            let weatherCode = currentCondition["weatherCode"] as? String ?? "116"

            let weatherDesc = (json["weather"] as? [[String: Any]])?.first
            let locationName = (json["nearest_area"] as? [[String: Any]])?.first?["areaName"] as? [[String: String]] ?? []
            let areaName = locationName.first?["value"]

            let condition = mapWeatherCode(weatherCode)

            return WeatherData(
                temperature: tempC,
                condition: condition,
                humidity: humidity / 100.0,
                uvIndex: uvIndex,
                date: date,
                location: areaName
            )
        } catch {
            return nil
        }
    }

    private func mapWeatherCode(_ code: String) -> WeatherData.WeatherCondition {
        // WMO weather codes mapping
        guard let codeInt = Int(code) else { return .cloudy }

        switch codeInt {
        case 113: return .sunny
        case 116: return .cloudy
        case 119, 122, 143: return .foggy
        case 176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 317, 320, 353, 356, 359, 362, 365, 377: return .rainy
        case 200, 386, 389, 392, 395: return .stormy
        case 227, 230, 248, 260: return .snowy
        case 179, 182, 185, 362, 364, 374, 377: return .snowy
        default: return .cloudy
        }
    }

    @MainActor
    private func getCurrentLocation() async -> CLLocation? {
        let status = locationManager.authorizationStatus

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            var received = false
            locationManager.requestLocation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if !received {
                    received = true
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func synthesizeWeatherForDate(_ date: Date) -> WeatherData {
        // Generate realistic synthesized weather for past dates
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Simple seasonal model
        let seasonalFactor = sin(Double(dayOfYear) / 365.0 * 2 * .pi)
        let baseTemp = 15.0 + seasonalFactor * 15.0

        let conditions: [WeatherData.WeatherCondition] = [.sunny, .cloudy, .rainy, .clear]
        let conditionIndex = abs(Int(date.timeIntervalSince1970)) % conditions.count

        return WeatherData(
            temperature: baseTemp + Double.random(in: -3...3),
            condition: conditions[conditionIndex],
            humidity: 0.4 + Double.random(in: 0...0.4),
            uvIndex: max(0, 5 + seasonalFactor * 5 + Double.random(in: -2...2)),
            date: date,
            location: nil
        )
    }
}
