//
//  TraveledStore.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/24/26.
//

import Foundation
import Combine

@MainActor
final class TraveledStore: ObservableObject {
    private let instanceId = UUID()

    @Published private(set) var ids: Set<String> = [] {
        didSet {
            print("📡 [TraveledStore:", instanceId, "] ids DID SET — count:", ids.count)
        }
    }

    private let saveKey = "traveled_country_ids_v2_iso2"

    init() {
        print("🧳 TraveledStore INIT — instance:", instanceId)
        load()
    }

    func contains(_ id: String) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: String) {
        print("🔁 [TraveledStore:", instanceId, "] toggle called for:", id)
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        save()
    }
    
    func replace(with ids: Set<String>) {
        print("♻️ [TraveledStore:", instanceId, "] replace called — new count:", ids.count)
        self.ids = ids
        save()
    }

    func clear() {
        print("🧹 [TraveledStore:", instanceId, "] clear called")
        ids.removeAll()
        save()
    }

    private func load() {
        print("📥 [TraveledStore:", instanceId, "] load from UserDefaults")
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            print("   no saved traveled data found")
            return
        }
        if let decoded = try? JSONDecoder().decode([String].self, from: data) {
            ids = Set(decoded)
            print("   loaded traveled count:", ids.count)
        } else {
            print("   failed to decode traveled data")
        }
    }

    private func save() {
        let array = Array(ids)
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: saveKey)
            print("💾 [TraveledStore:", instanceId, "] save — count:", ids.count)
        } else {
            print("❌ [TraveledStore:", instanceId, "] save failed to encode")
        }
    }
}
