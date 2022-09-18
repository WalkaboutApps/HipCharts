//
//  UserDefaults+Codable.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation

extension UserDefaults {
    func setCodable<T: Codable>(_ codable: T, forKey key: String) {
        guard let jsonData = try? JSONEncoder().encode(codable) else {
            logger.log("Failed to store Download Areas")
            return
        }
        set(jsonData, forKey: key)
    }
    
    func codable<T: Codable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
