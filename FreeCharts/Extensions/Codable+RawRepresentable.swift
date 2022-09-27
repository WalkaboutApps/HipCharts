//
//  Codable+RawRepresentable.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/27/22.
//

import SwiftUI

protocol CodableAndRawRepresentable: Codable, RawRepresentable { }

/// Requires manual conformance to Codable or will stack overflow
extension CodableAndRawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return result
    }
}

//extension SceneStorage {
//    init(wrappedValue: Value, _ key: String) where Value == MapRegionChangeEvent {
//
//    }
//}
