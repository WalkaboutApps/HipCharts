//
//  Polygon+Region.swift
//  HipCharts
//
//  Created by Fish Sticks on 10/1/22.
//

import Foundation
import Turf
import MapKit

extension Polygon {
    var region: MKCoordinateRegion? {
        guard let bbox = BoundingBox(from: coordinates[0]) else { return nil }
        let center = CLLocationCoordinate2D(latitude: (bbox.northEast.latitude + bbox.southWest.latitude) / 2,
                                            longitude: (bbox.northEast.longitude + bbox.southWest.longitude) / 2)
        return .init(center: center,
                     span: .init(latitudeDelta: bbox.northEast.latitude - bbox.southWest.latitude,
                                 longitudeDelta: bbox.northEast.longitude - bbox.southWest.longitude))
    }
}
