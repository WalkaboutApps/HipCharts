//
//  MKCoordinateRegion+Codable.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation
import MapKit
import CoreLocation


extension MKCoordinateRegion: Codable {
    enum CodingKeys: String, CodingKey {
        case centerLon, centerLat, spanLon, spanLat
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center.latitude, forKey: .centerLat)
        try container.encode(center.longitude, forKey: .centerLon)
        try container.encode(span.latitudeDelta, forKey: .spanLat)
        try container.encode(span.longitudeDelta, forKey: .spanLon)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let centerLat = try container.decode(CLLocationDegrees.self, forKey: .centerLat)
        let centerLon = try container.decode(CLLocationDegrees.self, forKey: .centerLon)
        let spanLat = try container.decode(CLLocationDegrees.self, forKey: .spanLat)
        let spanLon = try container.decode(CLLocationDegrees.self, forKey: .spanLon)
        
        self.init(center: .init(latitude: centerLat, longitude: centerLon),
                  span: .init(latitudeDelta: spanLat, longitudeDelta: spanLon))
    }
}

extension MKCoordinateRegion {
    var northEast: CLLocationCoordinate2D {
        .init(latitude: center.latitude + span.latitudeDelta / 2,
              longitude: center.longitude + span.longitudeDelta / 2)
    }
    
    var southWest: CLLocationCoordinate2D {
        .init(latitude: center.latitude - span.latitudeDelta / 2,
              longitude: center.longitude - span.longitudeDelta / 2)
    }
    
    var northWest: CLLocationCoordinate2D {
        .init(latitude: center.latitude + span.latitudeDelta / 2,
              longitude: center.longitude - span.longitudeDelta / 2)
    }
    
    var southEast: CLLocationCoordinate2D {
        .init(latitude: center.latitude - span.latitudeDelta / 2,
              longitude: center.longitude + span.longitudeDelta / 2)
    }
}
