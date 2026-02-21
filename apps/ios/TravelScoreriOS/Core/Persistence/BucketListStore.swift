//
//  BucketListStore.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/23/26.
//

import Foundation
import Combine

@MainActor
final class BucketListStore: ObservableObject {
    private let instanceId = UUID()

    @Published private(set) var ids: Set<String> = [] {
        didSet {
            print("📦 [BucketListStore:", instanceId, "] ids DID SET — count:", ids.count)
        }
    }

    private let saveKey = "bucket_list_country_ids_v2_iso2"

    init() {
        print("🧠 BucketListStore INIT — instance:", instanceId)
        load()
    }

    func contains(_ id: String) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: String) {
        print("🔄 [BucketListStore:", instanceId, "] toggle called for:", id)
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        print("📦 [BucketListStore:", instanceId, "] ids after toggle:", ids.sorted())
        save()
    }

    func add(_ id: String) {
        print("➕ [BucketListStore:", instanceId, "] add called for:", id)
        ids.insert(id)
        print("📦 [BucketListStore:", instanceId, "] ids after add:", ids.sorted())
        save()
    }

    func remove(_ id: String) {
        print("➖ [BucketListStore:", instanceId, "] remove called for:", id)
        ids.remove(id)
        print("📦 [BucketListStore:", instanceId, "] ids after remove:", ids.sorted())
        save()
    }
    
    func replace(with ids: Set<String>) {
        print("🔁 [BucketListStore:", instanceId, "] replace called — new count:", ids.count)
        print("📦 [BucketListStore:", instanceId, "] ids BEFORE replace:", self.ids.sorted())
        self.ids = ids
        print("📦 [BucketListStore:", instanceId, "] ids AFTER replace:", self.ids.sorted())
        save()
    }

    func clear() {
        print("🧹 [BucketListStore:", instanceId, "] clear called")
        ids.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            print("📦 [BucketListStore:", instanceId, "] load — nothing in UserDefaults")
            return
        }
        if let decoded = try? JSONDecoder().decode([String].self, from: data) {
            ids = Set(decoded)
            print("📦 [BucketListStore:", instanceId, "] load — loaded count:", ids.count)
        } else {
            print("❌ [BucketListStore:", instanceId, "] load — decode failed")
        }
    }

    private func save() {
        let array = Array(ids)
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: saveKey)
            print("💾 [BucketListStore:", instanceId, "] save — count:", ids.count)
        } else {
            print("❌ [BucketListStore:", instanceId, "] save — encode failed")
        }
    }
    
    deinit {
        print("💀 BucketListStore DEINIT — instance:", instanceId)
    }
}
