//
//  ChartTileLayer.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation
import MapKit

enum ChartTextSize: Int, Codable, CaseIterable {
    case small = 90
    case medium = 180
    case large = 360
}

enum DepthUnit: Int, Codable, CaseIterable {
    case meters = 1
    case feet = 2
    case fathoms = 3
}

class ChartTileOverlay: MKTileOverlay {
    static let minimumZ = 3
    static let maximumZ = 17
    
    let options: MapState.Options.Chart
    
    private let downloadManager: DownloadManager
    private let tileLoader: TileNetworkLoader
    
    private lazy var displayParams = ChartDisplayParams(ECDISParameters:
            .init(DynamicParameters: .init(Parameter: [
                .init(name: .DisplayDepthUnits, value: .integer(options.depthUnit.rawValue))
            ],
                                           ParameterGroup: nil))).escapedQueryString
    
    required init(options: MapState.Options.Chart,
                  downloadManager: DownloadManager = app.dependencies.downloadManager,
                  tileLoader: TileNetworkLoader = app.dependencies.tileLoader) {
        self.options = options
        self.downloadManager = downloadManager
        self.tileLoader = tileLoader
        super.init(urlTemplate: nil)
        
        maximumZ = Self.maximumZ
        minimumZ = Self.minimumZ
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        urlAndCenter(forTilePath: path).0
    }
    
    private func urlAndCenter(forTilePath path: MKTileOverlayPath) -> (URL, CLLocationCoordinate2D) {
        let dpi = options.highQuality ? options.textSize.rawValue : options.textSize.rawValue / 2
        var warningLayersParam = options.showChartAreasAndLimits ? "&layers=show:2,3,4,5,6,7" : "&layers=show:2,6"
        warningLayersParam = warningLayersParam.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let tileWidth = Int(options.highQuality ? tileSize.width : tileSize.width / 2)

        let bottomRightCoord = topLeftCoordinateOfXYZTile(x: path.x, y: path.y, z: path.z)
        let (minY, maxX) = convertToWebMercator(coordinate: bottomRightCoord)
        let (maxY, minX) = convertToWebMercator(coordinate: topLeftCoordinateOfXYZTile(x: path.x + 1, y: path.y + 1, z: path.z))
        
        let urlString = "https://gis.charttools.noaa.gov/arcgis/rest/services/MCS/NOAAChartDisplay/MapServer/exts/MaritimeChartService/MapServer/export" +
        "?transparent=true\(warningLayersParam)&size=\(tileWidth)%2C\(tileWidth)&bbox=\(minY)%2C\(minX)%2C\(maxY)%2C\(maxX)&bboxsr=3857&imagesr=3857&dpi=\(dpi)&display_params=\(displayParams)"
        return (URL(string: urlString)!,
                .init(latitude: .init(bottomRightCoord.lat),
                      longitude: .init(bottomRightCoord.lon)))
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        if let data = downloadManager.getTile(path: path) {
            result(data, nil)
        } else {
//            result(nil, NSError(domain: "fish", code: 9))
            let (url, coordinate) = urlAndCenter(forTilePath: path)
            tileLoader.load(.init(url: url, coordinate: coordinate, zoomLevel: path.z), completion: result)
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

/*
 
 layers: (13)
 id: 0
 name: Information about the chart display
 defaultVisibility: true
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 1
 name: Natural and man-made features, port features
 defaultVisibility: true
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 2
 name: Depths, currents, etc
 defaultVisibility: true
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 3
 name: Seabed, obstructions, pipelines
 defaultVisibility: true
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 4
 name: Traffic routes
 defaultVisibility: true
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 5
 name: Special areas
 defaultVisibility: true
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 6
 name: Buoys, beacons, lights, fog signals, radar
 defaultVisibility: true
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 7
 name: Services and small craft facilities
 defaultVisibility: true
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 8
 name: Data quality
 defaultVisibility: false
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 9
 name: Low accuracy
 defaultVisibility: false
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 10
 name: Additional chart information
 defaultVisibility: false
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 11
 name: Shallow water pattern
 defaultVisibility: false
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 id: 12
 name: Overscale warning
 defaultVisibility: false
 parentLayerId: -1
 subLayerIds: N/A
 minScale: 0
 maxScale: 0

 */
