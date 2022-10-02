//
//  CLLocationCoordinate2D+WA.swift
//  MapStretch
//
//  Created by Tyler on 4/16/17.
//  Copyright © 2017 Walkabout Apps. All rights reserved.
//

import CoreLocation



func * (lhs: CLLocationCoordinate2D, rhs: Double) -> CLLocationCoordinate2D{
    return CLLocationCoordinate2D(latitude: lhs.latitude * rhs, longitude: lhs.longitude * rhs)
}

extension CLLocationCoordinate2D {
    
    func metersFrom(_ coord: CLLocationCoordinate2D) -> Double{
        let R = 6371e3; // metres
        let toRadians = Double.pi/180
        let φ1 = self.latitude * toRadians
        let φ2 = coord.latitude * toRadians
        let Δφ = (coord.latitude-self.latitude) * toRadians
        let Δλ = (coord.longitude-self.longitude) * toRadians
        
        let a = sin(Δφ/2) * sin(Δφ/2) + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2);
        let c = 2 * atan2(sqrt(a), sqrt(1-a));
        
        let d = R * c;
        return d;
    }
}
    
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case lat, lon
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .lat)
        try container.encode(longitude, forKey: .lon)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .lat)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .lon)
        
        self.init(latitude: latitude, longitude: longitude)
    }
}
