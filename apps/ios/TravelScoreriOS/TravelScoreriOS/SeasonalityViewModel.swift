//
//  SeasonalityViewModel.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 12/2/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SeasonalityViewModel: ObservableObject {

    @Published var selectedMonth: Int
    @Published var peakCountries: [SeasonalityCountry]
    @Published var shoulderCountries: [SeasonalityCountry]
    @Published var selectedCountry: SeasonalityCountry?

    @Published var isLoading: Bool
    @Published var loadError: String?

    private let service: SeasonalityService

    private struct CountryMeta {
        let name: String
        let score: Double?
        let region: String?

        // Drawer snapshot scores (0–100)
        let advisory: Double?
        let affordability: Double?
        let visaEase: Double?
        let seasonality: Double?

        // Advisory level (1–4) if available
        let advisoryLevel: Int?
    }

    private var countryMetaByISO: [String: CountryMeta] = [:]

    // MARK: - Local-first cache for seasonality (per-month)

    private func applyCachedSeasonalityIfAvailable(forMonth month: Int) {
        guard let cached = SeasonalityCache.load(month: month) else { return }

        selectedMonth = cached.month

        // Enrich cached lists if we already have meta; otherwise show cached as-is
        let peak = enrich(cached.peak)
        let shoulder = enrich(cached.shoulder)

        peakCountries = peak
        shoulderCountries = shoulder

        if selectedCountry == nil {
            selectedCountry = peak.first ?? shoulder.first
        }

        loadError = nil

#if DEBUG
        print("💾 [SeasonalityViewModel] Loaded cached seasonality for month \(month) (peak=\(peak.count), shoulder=\(shoulder.count))")
#endif
    }

    private enum SeasonalityCache {
        private static let filePrefix = "seasonality_month_"
        private static let fileSuffix = "_v1.json"
        private static let refreshKeyPrefix = "seasonality_last_refresh_month_"
        private static let refreshKeySuffix = "_v1"

        struct Payload: Codable {
            let month: Int
            let peak: [CountryItem]
            let shoulder: [CountryItem]
            let savedAt: TimeInterval

            var peakCountries: [SeasonalityCountry] { peak.map { $0.toModel() } }
            var shoulderCountries: [SeasonalityCountry] { shoulder.map { $0.toModel() } }
        }

        struct CountryItem: Codable {
            let isoCode: String
            let name: String?
            let score: Double?
            let region: String?
            let advisoryLevel: Int?
            let scores: ScoreItem?

            struct ScoreItem: Codable {
                let advisory: Double?
                let seasonality: Double?
                let affordability: Double?
                let visaEase: Double?
            }

            init(from model: SeasonalityCountry) {
                self.isoCode = model.isoCode
                self.name = model.name
                self.score = model.score
                self.region = model.region
                self.advisoryLevel = model.advisoryLevel
                if let s = model.scores {
                    self.scores = ScoreItem(
                        advisory: s.advisory,
                        seasonality: s.seasonality,
                        affordability: s.affordability,
                        visaEase: s.visaEase
                    )
                } else {
                    self.scores = nil
                }
            }

            func toModel() -> SeasonalityCountry {
                let snapshot: SeasonalityCountry.ScoreSnapshot? = {
                    guard let s = scores else { return nil }
                    return SeasonalityCountry.ScoreSnapshot(
                        advisory: s.advisory,
                        seasonality: s.seasonality,
                        affordability: s.affordability,
                        visaEase: s.visaEase
                    )
                }()

                return SeasonalityCountry(
                    isoCode: isoCode,
                    name: name,
                    score: score,
                    region: region,
                    advisoryLevel: advisoryLevel,
                    scores: snapshot
                )
            }
        }

        static func save(month: Int, peak: [SeasonalityCountry], shoulder: [SeasonalityCountry]) {
            let payload = Payload(
                month: month,
                peak: peak.map { CountryItem(from: $0) },
                shoulder: shoulder.map { CountryItem(from: $0) },
                savedAt: Date().timeIntervalSince1970
            )
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(payload)
                try data.write(to: fileURL(for: month), options: [.atomic])
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: refreshKey(for: month))
#if DEBUG
                print("💾 [SeasonalityCache] Saved month \(month)")
#endif
            } catch {
#if DEBUG
                print("🔴 [SeasonalityCache] Save failed:", error)
#endif
            }
        }

        static func load(month: Int) -> (month: Int, peak: [SeasonalityCountry], shoulder: [SeasonalityCountry])? {
            do {
                let data = try Data(contentsOf: fileURL(for: month))
                let decoder = JSONDecoder()
                let payload = try decoder.decode(Payload.self, from: data)
                return (payload.month, payload.peakCountries, payload.shoulderCountries)
            } catch {
                return nil
            }
        }

        static func shouldRefresh(month: Int, minInterval: TimeInterval) -> Bool {
            let last = UserDefaults.standard.double(forKey: refreshKey(for: month))
            guard last > 0 else { return true }
            return (Date().timeIntervalSince1970 - last) >= minInterval
        }

        private static func refreshKey(for month: Int) -> String {
            "\(refreshKeyPrefix)\(month)\(refreshKeySuffix)"
        }

        private static func fileURL(for month: Int) -> URL {
            let fm = FileManager.default
            let dir = (try? fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? fm.temporaryDirectory
            return dir.appendingPathComponent("\(filePrefix)\(month)\(fileSuffix)")
        }
    }

#if DEBUG
    private func debugMirrorTree(_ value: Any, name: String = "root", depth: Int = 0, maxDepth: Int = 4) {
        if depth > maxDepth { return }

        let unwrapped = unwrapOptional(value) ?? value
        let m = Mirror(reflecting: unwrapped)

        let indent = String(repeating: "  ", count: depth)
        let typeName = String(describing: Swift.type(of: unwrapped))
        print("\(indent)↳ \(name): \(typeName) [\(String(describing: m.displayStyle))]")

        for child in m.children {
            let label = child.label ?? "(nil)"
            // Try to show scalar values inline; otherwise recurse.
            if let d = coerceToDouble(child.value) {
                print("\(indent)  • \(label): \(d)")
            } else {
                let childUnwrapped = unwrapOptional(child.value) ?? child.value
                let childMirror = Mirror(reflecting: childUnwrapped)
                // Only recurse into things that look like structs/classes/enums/collections.
                if childMirror.children.isEmpty {
                    // Leaf value that isn't numeric
                    print("\(indent)  • \(label): \(String(describing: childUnwrapped))")
                } else {
                    debugMirrorTree(child.value, name: label, depth: depth + 1, maxDepth: maxDepth)
                }
            }
        }
    }

    private func debugMissingMeta(for country: Any, iso: String, name: String, advisory: Double?, affordability: Double?) {
        guard advisory == nil || affordability == nil else { return }
        print("🧪 [SeasonalityViewModel] Missing meta for \(name) (\(iso)) advisory=\(String(describing: advisory)) affordability=\(String(describing: affordability))")
        debugMirrorTree(country, name: "Country")
        print("🧪 [SeasonalityViewModel] --- end mirror for \(name) (\(iso))")
    }
#endif

    // Mirror returns Optional(...) wrappers; unwrap them so path lookup works reliably.
    private func unwrapOptional(_ any: Any) -> Any? {
        let m = Mirror(reflecting: any)
        guard m.displayStyle == .optional else { return any }
        return m.children.first?.value
    }

    private func coerceToDouble(_ any: Any) -> Double? {
        // Unwrap optionals (possibly nested)
        var cur: Any? = any
        while let c = cur, Mirror(reflecting: c).displayStyle == .optional {
            cur = unwrapOptional(c)
        }
        guard let v = cur else { return nil }

        if let d = v as? Double { return d }
        if let i = v as? Int { return Double(i) }
        if let f = v as? Float { return Double(f) }
        if let s = v as? String {
            // Allow numeric strings just in case
            return Double(s)
        }
        return nil
    }

    private func coerceToString(_ any: Any) -> String? {
        // Unwrap optionals (possibly nested)
        var cur: Any? = any
        while let c = cur, Mirror(reflecting: c).displayStyle == .optional {
            cur = unwrapOptional(c)
        }
        guard let v = cur else { return nil }
        return v as? String
    }

    private func extractAnyPath(_ root: Any, path: [String]) -> Any? {
        // Walk a property path using Mirror labels, safely handling Optional wrappers.
        var currentAny: Any? = root

        for (idx, key) in path.enumerated() {
            guard let cur = currentAny else { return nil }

            let unwrapped = unwrapOptional(cur) ?? cur
            let m = Mirror(reflecting: unwrapped)

            guard let child = m.children.first(where: { $0.label == key }) else {
                return nil
            }

            if idx == path.count - 1 {
                return unwrapOptional(child.value) ?? child.value
            }

            currentAny = unwrapOptional(child.value) ?? child.value
        }

        return nil
    }

    private func parseAdvisoryLevel(_ any: Any?) -> Int? {
        guard let any else { return nil }

        // Accept numeric levels directly
        if let d = coerceToDouble(any) {
            let rounded = Int(d.rounded())
            return (1...4).contains(rounded) ? rounded : nil
        }

        // Accept strings like "Level 2"
        if let s = coerceToString(any) {
            let digits = s.compactMap { $0.wholeNumberValue }
            if let first = digits.first, (1...4).contains(first) {
                return first
            }
        }

        return nil
    }

    private func mapLevelToAdvisoryScore(_ level: Int?) -> Double? {
        guard let level else { return nil }
        let clamped = min(max(level, 1), 4)
        // Level 1 -> 100, Level 2 -> 75, Level 3 -> 50, Level 4 -> 25
        return Double(5 - clamped) * 25.0
    }

    private func affordabilityFromDailySpend(totalUsd: Double?) -> Double? {
        // Lower spend = higher affordability score.
        guard let totalUsd else { return nil }

        // Pragmatic placeholder scaling (tune later)
        let minUsd: Double = 35
        let maxUsd: Double = 250

        let clamped = min(max(totalUsd, minUsd), maxUsd)
        let t = (clamped - minUsd) / (maxUsd - minUsd) // 0..1
        return (1.0 - t) * 100.0
    }

    private func extractDoublePath(_ root: Any, path: [String]) -> Double? {
        // Walk a property path using Mirror labels, safely handling Optional wrappers.
        var currentAny: Any? = root

        for (idx, key) in path.enumerated() {
            guard let cur = currentAny else { return nil }

            // Unwrap optionals before mirroring
            let unwrapped = unwrapOptional(cur) ?? cur
            let m = Mirror(reflecting: unwrapped)

            guard let child = m.children.first(where: { $0.label == key }) else {
                return nil
            }

            if idx == path.count - 1 {
                return coerceToDouble(child.value)
            }

            // Continue down the path
            currentAny = unwrapOptional(child.value) ?? child.value
        }

        return nil
    }

    private func extractDoubleDeep(_ root: Any, keys: Set<String>, maxDepth: Int = 3) -> Double? {
        // Depth-limited DFS over Mirror children.
        func dfs(_ current: Any, depth: Int) -> Double? {
            if depth < 0 { return nil }

            let unwrapped = unwrapOptional(current) ?? current
            let m = Mirror(reflecting: unwrapped)

            for child in m.children {
                guard let label = child.label else { continue }

                if keys.contains(label) {
                    if let v = coerceToDouble(child.value) { return v }
                    if let nested = dfs(child.value, depth: depth - 1) { return nested }
                    continue
                }

                if let nested = dfs(child.value, depth: depth - 1) { return nested }
            }

            return nil
        }

        return dfs(root, depth: maxDepth)
    }

    private func makeSnapshot(
        advisory: Double?,
        seasonality: Double?,
        affordability: Double?,
        visaEase: Double?
    ) -> SeasonalityCountry.ScoreSnapshot? {
        // If everything is nil, keep it nil (UI can fall back)
        if advisory == nil && seasonality == nil && affordability == nil && visaEase == nil { return nil }

        // Use the explicit memberwise init we added in SeasonalityModels.swift
        return SeasonalityCountry.ScoreSnapshot(
            advisory: advisory,
            seasonality: seasonality,
            affordability: affordability,
            visaEase: visaEase
        )
    }

    init(
        service: SeasonalityService = SeasonalityService(),
        initialMonth: Int = Calendar.current.component(.month, from: Date())
    ) {
        self.service = service
        self.selectedMonth = initialMonth
        self.peakCountries = []
        self.shoulderCountries = []
        self.selectedCountry = nil
        self.isLoading = false
        self.loadError = nil
    }

    func loadInitial() {
        Task {
            // 0) Load cached seasonality for the initial month immediately (offline/fast)
            applyCachedSeasonalityIfAvailable(forMonth: selectedMonth)

            // 1) Load country meta (names/scores) from cache if possible, then from network
            await loadCountryMetaIfNeeded()

            // 2) Load seasonality (will use cache + refresh)
            await load(forMonth: selectedMonth)
        }
    }

    private func loadCountryMetaIfNeeded() async {
        // Only fetch once per app session for this view model instance
        if !countryMetaByISO.isEmpty { return }

        do {
            let countries: [Country]
            if let cached = CountryAPI.loadCachedCountries(), !cached.isEmpty {
                countries = cached
            } else if let refreshed = await CountryAPI.refreshCountriesIfNeeded(minInterval: 60), !refreshed.isEmpty {
                countries = refreshed
            } else {
                countries = try await CountryAPI.fetchCountries()
            }
            var map: [String: CountryMeta] = [:]
            for c in countries {
                // Country model uses `iso2` in this codebase (see CountryAPI mapping)
                let iso = c.iso2.uppercased()

                // Advisory: prefer travelSafeScore (0–100). Fallback to mapped advisoryLevel.
                let advisoryLevel =
                    parseAdvisoryLevel(extractAnyPath(c, path: ["advisoryLevel"]))
                    ?? parseAdvisoryLevel(extractAnyPath(c, path: ["advisory", "level"]))

                let advisoryScore =
                    extractDoublePath(c, path: ["travelSafeScore"]) // what your Country model actually has
                    ?? extractDoublePath(c, path: ["advisoryScore"])
                    ?? mapLevelToAdvisoryScore(advisoryLevel)

                // Affordability: derive from dailySpendTotalUsd (temporary proxy)
                let dailyTotal =
                    extractDoublePath(c, path: ["dailySpendTotalUsd"])
                    ?? {
                        let hotel = extractDoublePath(c, path: ["dailySpendHotelUsd"]) ?? 0
                        let food = extractDoublePath(c, path: ["dailySpendFoodUsd"]) ?? 0
                        let act = extractDoublePath(c, path: ["dailySpendActivitiesUsd"]) ?? 0
                        let sum = hotel + food + act
                        return sum > 0 ? sum : nil
                    }()

                let affordabilityScore = affordabilityFromDailySpend(totalUsd: dailyTotal)

                let visaEase =
                    extractDoublePath(c, path: ["visaEaseScore"]) // what your Country model actually has
                    ?? extractDoublePath(c, path: ["scores", "visaEase"]) // fallback shapes
                    ?? extractDoublePath(c, path: ["visaEase", "score"])
                    ?? extractDoubleDeep(c, keys: ["visaEaseScore", "visaEase"], maxDepth: 4)

                let seasonality =
                    extractDoublePath(c, path: ["seasonalityScore"]) // what your Country model actually has
                    ?? extractDoublePath(c, path: ["scores", "seasonality"])
                    ?? extractDoublePath(c, path: ["seasonality", "score"])
                    ?? extractDoubleDeep(c, keys: ["seasonalityScore", "seasonality"], maxDepth: 4)

#if DEBUG
                debugMissingMeta(for: c, iso: iso, name: c.name, advisory: advisoryScore, affordability: affordabilityScore)
#endif

                map[iso] = CountryMeta(
                    name: c.name,
                    score: {
                        // In this codebase, `Country.score` may be an `Int` (or optional). Convert to Double for UI.
                        if let s = c.score as? Double { return s }
                        if let s = c.score as? Int { return Double(s) }
                        if let s = c.score as? Int? { return s.map(Double.init) }
                        if let s = c.score as? Double? { return s }
                        return nil
                    }(),

                    region: c.region,

                    advisory: advisoryScore,
                    affordability: affordabilityScore,
                    visaEase: visaEase,
                    seasonality: seasonality,
                    advisoryLevel: advisoryLevel
                )
            }
            countryMetaByISO = map
        } catch {
            // Non-fatal: seasonality can still render with ISO codes.
            // Keep loadError reserved for seasonality endpoint failures.
            print("⚠️ [SeasonalityViewModel] Failed to load country metadata:", error)
        }
    }

    private func enrich(_ list: [SeasonalityCountry]) -> [SeasonalityCountry] {
        guard !countryMetaByISO.isEmpty else { return list }

        return list.map { c in
            let iso = c.isoCode.uppercased()
            if let meta = countryMetaByISO[iso] {
                return SeasonalityCountry(
                    isoCode: c.isoCode,
                    name: meta.name,
                    score: meta.score ?? c.score,
                    region: meta.region ?? c.region,
                    advisoryLevel: c.advisoryLevel ?? meta.advisoryLevel,
                    scores: makeSnapshot(
                        advisory: meta.advisory ?? c.scores?.advisory,
                        seasonality: meta.seasonality ?? c.scores?.seasonality,
                        affordability: meta.affordability ?? c.scores?.affordability,
                        visaEase: meta.visaEase ?? c.scores?.visaEase
                    )
                )
            }
            // Fallback: keep whatever came from the seasonality endpoint
            return c
        }
    }

    func load(forMonth month: Int) async {
        // 0) Show cached month results immediately (even if offline)
        applyCachedSeasonalityIfAvailable(forMonth: month)

        // If we have cached data and we're within cooldown, don't spam network
        if !SeasonalityCache.shouldRefresh(month: month, minInterval: 60) {
#if DEBUG
            print("🟡 [SeasonalityViewModel] Skipping seasonality refresh for month \(month) (cooldown)")
#endif
            return
        }

        // Show spinner only if we don't have anything to show yet
        if peakCountries.isEmpty && shoulderCountries.isEmpty {
            isLoading = true
        } else {
            isLoading = false
        }
        loadError = nil

        do {
            // Ensure we have country names/scores to display
            await loadCountryMetaIfNeeded()

            let response = try await service.fetchSeasonality(forMonth: month)
            selectedMonth = response.month

            let enrichedPeak = enrich(response.peak)
            let enrichedShoulder = enrich(response.shoulder)

            peakCountries = enrichedPeak
            shoulderCountries = enrichedShoulder

            // Cache the raw seasonality result (as a lightweight Codable payload)
            SeasonalityCache.save(month: response.month, peak: response.peak, shoulder: response.shoulder)

            // Reset selection when month changes
            if let first = enrichedPeak.first {
                selectedCountry = first
            } else {
                selectedCountry = enrichedShoulder.first
            }
        } catch {
            // If we already showed cached data, keep it and show a soft error
            if peakCountries.isEmpty && shoulderCountries.isEmpty {
                loadError = error.localizedDescription
            } else {
#if DEBUG
                print("⚠️ [SeasonalityViewModel] Refresh failed but cache shown:", error)
#endif
            }
        }

        isLoading = false
    }

    func select(_ country: SeasonalityCountry) {
        selectedCountry = country
    }
}

// MARK: - Convenience init for enrichment

extension SeasonalityCountry {
    /// Memberwise initializer used by SeasonalityViewModel when enriching API results
    /// with metadata (name/score/region). This exists because we added a custom
    /// `init(from:)` in SeasonalityModels.swift, which removes the synthesized init.
    init(
        isoCode: String,
        name: String?,
        score: Double?,
        region: String?,
        advisoryLevel: Int?,
        scores: ScoreSnapshot?
    ) {
        self.isoCode = isoCode
        self.name = name
        self.score = score
        self.region = region
        self.advisoryLevel = advisoryLevel
        self.scores = scores
    }
}
