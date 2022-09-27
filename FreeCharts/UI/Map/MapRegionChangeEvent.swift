//
//  MapRegionChangeEvent.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/27/22.
//

import Foundation
import MapKit

struct MapRegionChangeEvent: Codable {
    enum Reason: String, Codable { case map, app }
    let reason: Reason
    let region: MKCoordinateRegion
    var animated: Bool = false
}

//extension MapRegionChangeEvent {
//    enum CodingKeys: String, CodingKey {
//        case reason, region, animated
//    }
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(reason, forKey: .reason)
//        try container.encode(region, forKey: .region)
//        try container.encode(animated, forKey: .animated)
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let reason = try container.decode(Reason.self, forKey: .reason)
//        let region = try container.decode(MKCoordinateRegion.self, forKey: .region)
//        let animated = try container.decode(Bool.self, forKey: .animated)
//
//        self.init(reason: reason, region: region, animated: animated)
//    }
//}
