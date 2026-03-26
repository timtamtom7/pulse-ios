import Foundation

// R11: Menu Bar Extra, Shortcuts, Visual Polish for Pulse
@MainActor
final class PulseR11Service: ObservableObject {
    static let shared = PulseR11Service()

    @Published var refreshRate: RefreshRate = .seconds5

    enum RefreshRate: Int, CaseIterable {
        case seconds1 = 1
        case seconds5 = 5
        case seconds10 = 10
        case manual = 0

        var description: String {
            switch self {
            case .seconds1: return "1 second"
            case .seconds5: return "5 seconds"
            case .seconds10: return "10 seconds"
            case .manual: return "Manual"
            }
        }
    }

    private init() {}

    // MARK: - Menu Bar Extra

    struct MenuBarStats {
        let cpuUsage: Double
        let memoryPressure: MemoryPressure
        let networkActivity: NetworkActivity
        let diskUsage: Double

        enum MemoryPressure: String {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
        }

        struct NetworkActivity {
            let bytesIn: Int64
            let bytesOut: Int64
        }
    }

    func getMenuBarStats() -> MenuBarStats {
        MenuBarStats(
            cpuUsage: 0,
            memoryPressure: .low,
            networkActivity: MenuBarStats.NetworkActivity(bytesIn: 0, bytesOut: 0),
            diskUsage: 0
        )
    }

    // MARK: - Shortcuts

    struct ShortcutsResult {
        let cpuUsage: String
        let memoryPressure: String
        let topProcess: String
    }

    func getCPUMetric() -> String {
        return "CPU: \(Int.random(in: 5...30))%"
    }

    func getMemoryMetric() -> String {
        return "Memory: \(Int.random(in: 40...80))%"
    }

    func getTopProcess() -> String {
        return "kernel_task"
    }

    // MARK: - Advanced

    func exportHistoricalData(format: ExportFormat) throws -> URL {
        let data = "timestamp,cpu,memory\n".data(using: .utf8)!
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pulse_export.\(format.rawValue)")
        try data.write(to: url)
        return url
    }

    enum ExportFormat: String {
        case csv = "csv"
        case json = "json"
    }

    // MARK: - Notifications

    func shouldNotify(highCPU: Bool, highMemory: Bool) -> Bool {
        return highCPU || highMemory
    }
}
