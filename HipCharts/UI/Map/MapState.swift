//
//  MapSceneState.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/27/22.
//

import Foundation

typealias ChartOptions = MapState.Options.Chart

struct MapState: CodableAndRawRepresentable {
    struct Options: Codable {
        struct Map: Codable {
            var showCharts = true
            var baseMap = MapType.standard
        }
        struct Chart: Codable, Equatable {
            var textSize = ChartTextSize.medium
            var showChartAreasAndLimits = true
            var highQuality = false
        }
        var map = Map()
        var chart = Chart()
    }
    var options = Options()
    var regionChangeEvent = MapRegionChangeEvent(reason: .app, region: .init())
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
