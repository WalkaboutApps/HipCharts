//
//  ChartTileLayer.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation
import MapKit

enum ChartTextSize: Int, Codable, CaseIterable {
    case large = 360
    case medium = 180
    case small = 90
}

class ChartTileOverlay: MKTileOverlay {
    static let minimumZ = 0
    static let maximumZ = 17
    
    let textSize: ChartTextSize
    
    private let downloadManager: DownloadManager
    
    required init(textSize: ChartTextSize,
                  downloadManager: DownloadManager = app.dependencies.downloadManager) {
        self.textSize = textSize
        self.downloadManager = downloadManager
        super.init(urlTemplate: nil)
        
        maximumZ = Self.maximumZ
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let dpi = textSize.rawValue
        let (minY, maxX) = convertToWebMercator(coordinate: topLeftCoordinateOfXYZTile(x: path.x, y: path.y, z: path.z))
        let (maxY, minX) = convertToWebMercator(coordinate: topLeftCoordinateOfXYZTile(x: path.x + 1, y: path.y + 1, z: path.z))
        
        let urlString = "https://gis.charttools.noaa.gov/arcgis/rest/services/MCS/NOAAChartDisplay/MapServer/exts/MaritimeChartService/MapServer/export?f=image&format=PNG32&transparent=true&layers=show%3A2%2C3%2C4%2C5%2C6%2C7&format=png8&size=\(tileSize.width)%2C\(tileSize.height)&bbox=\(minY)%2C\(minX)%2C\(maxY)%2C\(maxX)&bboxsr=3857&imagesr=3857&dpi=\(dpi)&transparent=true"
        return URL(string: urlString)!
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        if let data = downloadManager.getTile(path: path) {
            result(data, nil)
        } else {
//            result(nil, NSError(domain: "fish", code: 9))
            super.loadTile(at: path, result: result)
        }
    }
    
    private func convertToWebMercator(coordinate: (lat: Float, lon: Float)) -> (x: Float, y: Float) {
        let (lat, lon) = coordinate
        if abs(lon) <= 180, abs(lat) < 90 {
            let num = lon * 0.017453292519943295
            let x = 6378137.0 * num
            let a = lat * 0.017453292519943295
            let x_mercator = x
            let y_mercator = 3189068.5 * log((1.0 + sin(a)) / (1.0 - sin(a)))
            return (x: x_mercator, y: y_mercator)
        } else {
            logger.log("Invalid coordinate values for conversion")
            return (0, 0)
        }
    }

    private func topLeftCoordinateOfXYZTile(x: Int, y: Int, z: Int) -> (lat: Float, lon: Float) {
        let n = powf(2, Float(z))
        let lon_deg = Float(x) / n * 360 - 180
        let lat_rad = atan(sinh(Float(.pi * (1 - 2 * Float(y) / n))))
        let lat_deg = lat_rad * 180 / .pi
        return (lat_deg, lon_deg)
    }
}

// MARK: - Notes

// convert from xyz to ArcGIS bbox url
/*
 python impl
 This returns the NW-corner of the square. Use the function with xtile+1 and/or ytile+1 to get the other corners. With xtile+0.5 & ytile+0.5 it will return the center of the tile.
 
 https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
 import math
 def num2deg(xtile, ytile, zoom):
 n = 2.0 ** zoom
 lon_deg = xtile / n * 360.0 - 180.0
 lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * ytile / n)))
 lat_deg = math.degrees(lat_rad)
 return (lat_deg, lon_deg)
 
 */
// full working URL https://gis.charttools.noaa.gov/arcgis/rest/services/MCS/NOAAChartDisplay/MapServer/exts/MaritimeChartService/MapServer/export?f=image&format=PNG32&transparent=true&layers=show%3A2%2C3%2C4%2C5%2C6%2C7&format=png8&bboxsr=%7B%22wkid%22%3A3857%7D&size=4297%2C1407&bbox=-7958818.216247354%2C5190773.590516125%2C-7806649.333229041%2C5240599.426775553&bboxsr=3857&imagesr=3857&dpi=180

// simple working URL https://gis.charttools.noaa.gov/arcgis/rest/services/MCS/NOAAChartDisplay/MapServer/exts/MaritimeChartService/MapServer/export?size=256%2C256&bbox=-7958818.216247354%2C5190773.590516125%2C-7806649.333229041%2C5240599.426775553
// bbox = miny,minx,maxy,maxx
