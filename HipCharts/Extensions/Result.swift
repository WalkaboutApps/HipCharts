//
//  Result.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation

extension Result {
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
