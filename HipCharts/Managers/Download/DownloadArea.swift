//
//  DownloadArea.swift
//  HipCharts
//
//  Created by Fish Sticks on 10/1/22.
//

import Foundation
import MapKit
import Turf

struct DownloadArea: Codable {
    let id: UUID
    var name: String?
    let region: MKCoordinateRegion
    /// Date of last completed download
    var date: Date?
    var sizeBytes: Int?
    
    var customPolygon: Polygon? = nil
}
