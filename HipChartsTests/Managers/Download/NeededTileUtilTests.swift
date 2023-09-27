//
//  NeededTileUtilTests.swift
//  HipChartsTests
//
//  Created by Fish Sticks on 9/26/23.
//

import XCTest
import Turf
import MapKit
@testable import HipCharts


final class NeededTileUtilTests: XCTestCase {

    func testPolygonNeededTiles() {
        let polygon = Polygon([[
            .init(latitude: 0, longitude: 0),
            .init(latitude: 0.00001, longitude: 0.00002),
            .init(latitude: 0, longitude: 0.0001),
            .init(latitude: 0, longitude: 0),
        ]])
        
        let tiles = neededTiles(polygon: polygon)
        
        XCTAssertEqual(tiles, [
            TilePath(x: 4, y: 3, z: 3, contentScaleFactor: 2.0),
            TilePath(x: 4, y: 4, z: 3, contentScaleFactor: 2.0),
            TilePath(x: 8, y: 7, z: 4, contentScaleFactor: 2.0),
            TilePath(x: 8, y: 8, z: 4, contentScaleFactor: 2.0),
            TilePath(x: 16, y: 15, z: 5, contentScaleFactor: 2.0),
            TilePath(x: 16, y: 16, z: 5, contentScaleFactor: 2.0),
            TilePath(x: 32, y: 31, z: 6, contentScaleFactor: 2.0),
            TilePath(x: 32, y: 32, z: 6, contentScaleFactor: 2.0),
            TilePath(x: 64, y: 63, z: 7, contentScaleFactor: 2.0),
            TilePath(x: 64, y: 64, z: 7, contentScaleFactor: 2.0),
            TilePath(x: 128, y: 127, z: 8, contentScaleFactor: 2.0),
            TilePath(x: 128, y: 128, z: 8, contentScaleFactor: 2.0),
            TilePath(x: 256, y: 255, z: 9, contentScaleFactor: 2.0),
            TilePath(x: 256, y: 256, z: 9, contentScaleFactor: 2.0),
            TilePath(x: 512, y: 511, z: 10, contentScaleFactor: 2.0),
            TilePath(x: 512, y: 512, z: 10, contentScaleFactor: 2.0),
            TilePath(x: 1024, y: 1023, z: 11, contentScaleFactor: 2.0),
            TilePath(x: 1024, y: 1024, z: 11, contentScaleFactor: 2.0),
            TilePath(x: 2048, y: 2047, z: 12, contentScaleFactor: 2.0),
            TilePath(x: 2048, y: 2048, z: 12, contentScaleFactor: 2.0),
            TilePath(x: 4096, y: 4095, z: 13, contentScaleFactor: 2.0),
            TilePath(x: 4096, y: 4096, z: 13, contentScaleFactor: 2.0),
            TilePath(x: 8192, y: 8191, z: 14, contentScaleFactor: 2.0),
            TilePath(x: 8192, y: 8192, z: 14, contentScaleFactor: 2.0),
            TilePath(x: 16384, y: 16383, z: 15, contentScaleFactor: 2.0),
            TilePath(x: 16384, y: 16384, z: 15, contentScaleFactor: 2.0),
            TilePath(x: 32768, y: 32767, z: 16, contentScaleFactor: 2.0),
            TilePath(x: 32768, y: 32768, z: 16, contentScaleFactor: 2.0),
            TilePath(x: 65536, y: 65535, z: 17, contentScaleFactor: 2.0),
            TilePath(x: 65536, y: 65536, z: 17, contentScaleFactor: 2.0)
        ])
    }
    
    func testPolygonNeededTilesWithZRange() {
        let polygon = Polygon([[
            .init(latitude: 0, longitude: 0),
            .init(latitude: 0.00001, longitude: 0.00002),
            .init(latitude: 0, longitude: 0.00001),
            .init(latitude: 0, longitude: 0),
        ]])
        
        let tiles = neededTiles(polygon: polygon, zRange: 10 ... 12)
        
        XCTAssertEqual(tiles, [
            TilePath(x: 512, y: 511, z: 10, contentScaleFactor: 2.0),
            TilePath(x: 512, y: 512, z: 10, contentScaleFactor: 2.0),
            TilePath(x: 1024, y: 1023, z: 11, contentScaleFactor: 2.0),
            TilePath(x: 1024, y: 1024, z: 11, contentScaleFactor: 2.0),
            TilePath(x: 2048, y: 2047, z: 12, contentScaleFactor: 2.0),
            TilePath(x: 2048, y: 2048, z: 12, contentScaleFactor: 2.0),
        ])
    }

}
