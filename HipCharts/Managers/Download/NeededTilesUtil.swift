//
//  NeededTilesUtil.swift
//  HipCharts
//
//  Created by Fish Sticks on 10/1/22.
//

import Foundation
import MapKit
import Turf

func neededTiles(area: DownloadArea) -> [TilePath] {
    if let polygon = area.customPolygon {
        return neededTiles(polygon: polygon) ?? neededTiles(region: area.region)
    } else {
        return neededTiles(region: area.region)
    }
}

func neededTiles(polygon: Polygon,
                 zRange: ClosedRange<Int> = ChartTileOverlay.minimumZ ... ChartTileOverlay.maximumZ) -> [TilePath]? {
    guard let bbox = BoundingBox(from: polygon.coordinates[0]) else { return nil }
    let startTime = Date()
    defer {
        logger.log("Took \(Date().timeIntervalSince(startTime)) seconds to caculate needed tiles in Polygon.")
    }
    
    let polygonExteriorSegments = LineString(polygon.outerRing.coordinates).segments

    return zRange.flatMap { (z) -> [MKTileOverlayPath] in
        let topLeft = tilePath(.init(latitude: bbox.northEast.latitude,
                                     longitude: bbox.southWest.longitude), zoom: z)
        let bottomRight = tilePath(.init(latitude: bbox.southWest.latitude,
                                         longitude: bbox.northEast.longitude), zoom: z)
        return (topLeft.x ... bottomRight.x).flatMap { x in
            (topLeft.y ... bottomRight.y).compactMap { (y) -> TilePath? in
                let tile = TilePath(x: x, y: y, z: z)
                let tileExteriorSegments = tile.exteriorLineSegments
                
                // check for tile containing polygon
                let coords = tileExteriorSegments.map { $0.0 } + [tileExteriorSegments[0].0]
                let tilePolygon = Polygon(outerRing: .init(coordinates: coords))
                if tilePolygon.contains(polygon.coordinates[0][0]) {
                    return tile
                }
                
                // check for polygon containing tile
                if polygon.contains(tileExteriorSegments[0].0) {
                    return tile
                }
                
                // check for boundary intersection (expensive!)
                if tileExteriorSegments.first(where: { tileSegment in
                    polygonExteriorSegments.first(where:  { polygonSegment in
                        intersection(tileSegment, polygonSegment) != nil
                    }) != nil
                }) != nil {
                    return tile
                }

                return  nil
            }
        }
    }
}

extension LineString {
    var segments: [LineSegment] {
        return zip(coordinates.dropLast(), coordinates.dropFirst()).map { LineSegment($0.0, $0.1) }
    }
}

private extension TilePath {
    var exteriorLineSegments: [LineSegment] {
        let nw = degreesNWCorner(tile: self)
        let ne = degreesNWCorner(tile: .init(x: x + 1, y: y, z: z))
        let se = degreesNWCorner(tile: .init(x: x + 1, y: y + 1, z: z))
        let sw = degreesNWCorner(tile: .init(x: x, y: y + 1, z: z))
        return [
            (nw, ne),
            (ne, se),
            (se, sw),
            (sw, nw)
        ]
    }
}


private func neededTiles(region: MKCoordinateRegion,
                 zRange: ClosedRange<Int> = ChartTileOverlay.minimumZ ... ChartTileOverlay.maximumZ) -> [TilePath] {
    zRange.flatMap { (z) -> [MKTileOverlayPath] in
        let topLeft = tilePath(region.northWest, zoom: z)
        let bottomRight = tilePath(region.southEast, zoom: z)
        return (topLeft.x ... bottomRight.x).flatMap { x in
            (topLeft.y ... bottomRight.y).map {
                MKTileOverlayPath(x: x, y: $0, z: z)
            }
        }
    }
}

private func tilePath(_ coordinate: CLLocationCoordinate2D, zoom: Int) -> TilePath {
    let lat_rad = Float(coordinate.latitude) * .pi / 180
    let n = pow(2, Float(zoom))
    let xtile = Int((Float(coordinate.longitude) + 180.0) / 360.0 * n)
    let ytile = Int((1.0 - asinh(tan(lat_rad)) / .pi) / 2.0 * n)
    return .init(x: xtile, y: ytile, z: zoom, contentScaleFactor: 1)
}

private func degreesNWCorner(tile: TilePath) -> CLLocationCoordinate2D {
    let n = powf(2, Float(tile.z))
    let lon_deg = Float(tile.x) / n * 360.0 - 180.0
    let lat_rad = atan(sinh(.pi * (1 - 2 * Float(tile.y) / n)))
    let lat_deg = lat_rad * 180 / .pi
    return .init(latitude: CLLocationDegrees(lat_deg), longitude: CLLocationDegrees(lon_deg))
}
