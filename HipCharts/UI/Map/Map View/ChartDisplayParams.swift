//
//  ChartDisplayParams.swift
//  HipCharts
//
//  Created by Fish Sticks on 10/23/22.
//

import Foundation


// MARK: - ChartDisplayParams
struct ChartDisplayParams: Encodable {
    let ECDISParameters: ECDISParameters
    
    var escapedQueryString: String {
        let data = try! JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
}

// MARK: - ECDISParameters
struct ECDISParameters: Encodable {
    struct DynamicParameters: Codable {
        struct Parameter: Codable {
            enum Name: String, Codable { case DisplayDepthUnits }
            let name: Name
            let value: StringOrIntValue
        }
        
        struct ParameterGroup: Codable {
            struct Parameter: Codable {
                let name: String
                let value: Double
            }
            let name: String
            let Parameter: [Parameter]
        }
        
        let Parameter: [Parameter]
        let ParameterGroup: [ParameterGroup]?
    }
    
    let version = "10.9.1"
    let DynamicParameters: DynamicParameters
}

enum StringOrIntValue: Codable {
    case integer(Int)
    case string(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(StringOrIntValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Value"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        }
    }
}


// Pragma MARK: - Sample

/*
 {
     "ECDISParameters": {
         "version": "10.9.1",
         "DynamicParameters": {
             "Parameter": [{
                 "name": "AreaSymbolizationType",
                 "value": 2
             }, {
                 "name": "AttDesc",
                 "value": 1
             }, {
                 "name": "ColorScheme",
                 "value": 0
             }, {
                 "name": "CompassRose",
                 "value": 1
             }, {
                 "name": "DateDependencyRange",
                 "value": ""
             }, {
                 "name": "DateDependencySymbols",
                 "value": 1
             }, {
                 "name": "DeepContour",
                 "value": 30
             }, {
                 "name": "DisplayAIOFeatures",
                 "value": "1,2,3,4,5,6,7"
             }, {
                 "name": "DisplayBathymetricIENC",
                 "value": 1
             }, {
                 "name": "DisplayCategory",
                 "value": "1,2,4"
             }, {
                 "name": "DisplayDepthUnits",
                 "value": 2
             }, {
                 "name": "DisplayFrames",
                 "value": 3
             }, {
                 "name": "DisplayFrameText",
                 "value": 0
             }, {
                 "name": "DisplayFrameTextPlacement",
                 "value": 1
             }, {
                 "name": "DisplayLightSectors",
                 "value": 2
             }, {
                 "name": "DisplayNOBJNM",
                 "value": 2
             }, {
                 "name": "DisplaySafeSoundings",
                 "value": 2
             }, {
                 "name": "HonorScamin",
                 "value": 2
             }, {
                 "name": "IntendedUsage",
                 "value": "0"
             }, {
                 "name": "IsolatedDangers",
                 "value": 1
             }, {
                 "name": "IsolatedDangersOff",
                 "value": 1
             }, {
                 "name": "LabelContours",
                 "value": 1
             }, {
                 "name": "LabelSafetyContours",
                 "value": 1
             }, {
                 "name": "MovingCentroid",
                 "value": 1
             }, {
                 "name": "OptionalDeepSoundings",
                 "value": 1
             }, {
                 "name": "PointSymbolizationType",
                 "value": 2
             }, {
                 "name": "RemoveDuplicateText",
                 "value": 2
             }, {
                 "name": "SafetyContour",
                 "value": 30
             }, {
                 "name": "SafetyDepth",
                 "value": 30
             }, {
                 "name": "ShallowContour",
                 "value": 2
             }, {
                 "name": "TextHalo",
                 "value": 2
             }, {
                 "name": "TwoDepthShades",
                 "value": 1
             }],
             "ParameterGroup": [{
                 "name": "AreaSymbolSize",
                 "Parameter": [{
                     "name": "scaleFactor",
                     "value": 1
                 }, {
                     "name": "minZoom",
                     "value": 0.05
                 }, {
                     "name": "maxZoom",
                     "value": 1.2
                 }]
             }, {
                 "name": "DatasetDisplayRange",
                 "Parameter": [{
                     "name": "minZoom",
                     "value": 0.05
                 }, {
                     "name": "maxZoom",
                     "value": 1.2
                 }]
             }, {
                 "name": "LineSymbolSize",
                 "Parameter": [{
                     "name": "scaleFactor",
                     "value": 1
                 }, {
                     "name": "minZoom",
                     "value": 0.05
                 }, {
                     "name": "maxZoom",
                     "value": 1.2
                 }]
             }, {
                 "name": "PointSymbolSize",
                 "Parameter": [{
                     "name": "scaleFactor",
                     "value": 1
                 }, {
                     "name": "minZoom",
                     "value": 0.05
                 }, {
                     "name": "maxZoom",
                     "value": 1.2
                 }]
             }, {
                 "name": "TextGroups",
                 "Parameter": [{
                     "name": "11",
                     "value": 2
                 }, {
                     "name": "21",
                     "value": 2
                 }, {
                     "name": "23",
                     "value": 2
                 }, {
                     "name": "24",
                     "value": 2
                 }, {
                     "name": "25",
                     "value": 2
                 }, {
                     "name": "26",
                     "value": 2
                 }, {
                     "name": "27",
                     "value": 2
                 }, {
                     "name": "28",
                     "value": 2
                 }, {
                     "name": "29",
                     "value": 2
                 }, {
                     "name": "30",
                     "value": 2
                 }]
             }, {
                 "name": "TextSize",
                 "Parameter": [{
                     "name": "scaleFactor",
                     "value": 1
                 }, {
                     "name": "minZoom",
                     "value": 0.05
                 }, {
                     "name": "maxZoom",
                     "value": 1.2
                 }]
             }]
         }
     }
 }
 */
