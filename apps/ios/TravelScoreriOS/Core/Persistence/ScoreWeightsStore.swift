//
//  ScoreWeightsStore.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/22/26.
//

import Foundation
import Combine

final class ScoreWeightsStore: ObservableObject {
    
    @Published var weights: ScoreWeights {
        didSet {
            save()
        }
    }
    
    private let key = "score_weights"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(ScoreWeights.self, from: data) {
            self.weights = decoded
        } else {
            self.weights = .default
        }
    }
    
    func resetToDefault() {
        weights = .default
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(weights) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

extension ScoreWeightsStore {

    var totalWeight: Double {
        weights.advisory +
        weights.seasonality +
        weights.visa +
        weights.affordability
    }

    func percentage(for keyPath: KeyPath<ScoreWeights, Double>) -> Int {
        let total = totalWeight
        guard total > 0 else { return 0 }
        let value = weights[keyPath: keyPath]
        return Int(((value / total) * 100).rounded())
    }

    var advisoryPercentage: Int {
        percentage(for: \.advisory)
    }

    var seasonalityPercentage: Int {
        percentage(for: \.seasonality)
    }

    var visaPercentage: Int {
        percentage(for: \.visa)
    }

    var affordabilityPercentage: Int {
        percentage(for: \.affordability)
    }
}
