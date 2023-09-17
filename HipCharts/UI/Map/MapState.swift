//
//  MapSceneState.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/27/22.
//

import Foundation
import MapKit

typealias ChartOptions = MapState.Options.Chart

let regionContainingUSA = MKCoordinateRegion(center: .init(latitude: 45.498251826915542,
                                                     longitude: -96.523667515936935),
                                       span: .init(latitudeDelta: 112.90309672478108,
                                                   longitudeDelta: 89.096406350250135
                                                  ))
// NOTE!!! values must be manually added to stored struct and coding keys below
struct MapState: CodableAndRawRepresentable {
    struct Options: Codable {
        // See note about editing above
        struct Map: Codable {
            var showCharts = true
            var baseMap = MapType.standard
            
            private var _measurementUnit: MeasurementUnit?
            var measurementUnit: MeasurementUnit {
                get { _measurementUnit ?? .nauticalMiles }
                set { _measurementUnit = newValue }
            }
        }
        // See note about editing above
        struct Chart: Codable, Equatable {
            var textSize = ChartTextSize.medium
            var showChartAreasAndLimits = true
            var highQuality = true
            
            private var _depthUnit: DepthUnit?
            var depthUnit: DepthUnit {
                get { _depthUnit ?? .feet }
                set { _depthUnit = newValue }
            }
        }
        // See note about editing above
        var map = Map()
        var chart = Chart()
    }
    // See note about editing above
    var options = Options()
    var regionChangeEvent = MapRegionChangeEvent(reason: .app, region: regionContainingUSA)
    
    // Not stored properties
    var showDrawing: DrawState?
}

extension MapState {
    enum CodingKeys: String, CodingKey {
        case options, regionChangeEvent
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(options, forKey: .options)
        try container.encode(regionChangeEvent, forKey: .regionChangeEvent)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let mapOptions = try container.decode(Options.self, forKey: .options)
        let mapChangeEvent = try container.decode(MapRegionChangeEvent.self, forKey: .regionChangeEvent)

        self.init(options: mapOptions, regionChangeEvent: mapChangeEvent)
    }
}
