import Foundation

public struct StateDistricts: Codable, Identifiable {
    public var id: String { state }
    public let state: String
    public let districts: [String]
}

public final class DistrictDataLoader {
    public static let shared = DistrictDataLoader()

    public private(set) var stateDistricts: [StateDistricts] = []

    private init() {
        loadData()
    }

    private func loadData() {
        guard let url = Bundle.main.url(forResource: "states_and_cities", withExtension: "json") else {
            // Fallback: look for Resources/states_and_cities.json
            return
        }
        do {
            let data = try Data(contentsOf: url)
            self.stateDistricts = try JSONDecoder().decode([StateDistricts].self, from: data)
        } catch {
            print("Error loading states_and_cities.json: \(error)")
        }
    }

    public var states: [String] {
        stateDistricts.map { $0.state }
    }

    public func districts(for state: String) -> [String] {
        stateDistricts.first { $0.state.caseInsensitiveCompare(state) == .orderedSame }?.districts ?? []
    }
}
