//
//  PaymentManager.swift
//  HipCharts
//
//  Created by Fish Sticks on 10/2/22.
//

import Foundation

enum PaidFeature: Int, CaseIterable {
    case download, polygonDownload, drawRoute
}

class PaymentManager {
    
    
    func hasAccessToPaidFeature(_ feature: PaidFeature) -> Bool {
        return false
    }
}
