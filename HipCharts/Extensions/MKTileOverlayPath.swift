//
//  MKOverlayTilePath.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import MapKit

typealias TilePath = MKTileOverlayPath

extension MKTileOverlayPath: Hashable {
    
    init(x: Int, y: Int, z: Int) {
        self.init(x: x, y: y, z: z, contentScaleFactor: 2)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(z)
        hasher.combine(x)
        hasher.combine(y)
//        hasher.combine(contentScaleFactor)
    }
    
    public static func == (lhs: MKTileOverlayPath, rhs: MKTileOverlayPath) -> Bool {
        lhs.z == rhs.z &&
        lhs.x == rhs.x &&
        lhs.y == rhs.y
//        lhs.contentScaleFactor == rhs.contentScaleFactor
    }
}
