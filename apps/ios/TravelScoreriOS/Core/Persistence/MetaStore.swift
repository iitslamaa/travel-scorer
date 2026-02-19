//
//  MetaStore.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/2/26.
//

import Foundation

import Foundation

final class MetaStore {
    private let key = "cached_meta"

    func load() -> MetaDTO? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(MetaDTO.self, from: data)
    }

    func save(_ meta: MetaDTO) {
        let data = try? JSONEncoder().encode(meta)
        UserDefaults.standard.set(data, forKey: key)
    }
}
