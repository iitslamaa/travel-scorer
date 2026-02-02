//
//  MetaService.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/2/26.
//

import Foundation

import Foundation

final class MetaService {
    func fetchMeta() async throws -> MetaDTO {
        let url = APIConfig.baseURL.appendingPathComponent("/api/meta")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MetaDTO.self, from: data)
    }
}
