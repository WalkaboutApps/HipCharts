//
//  MapDrawingView.swift
//  MapStretch
//
//  Created by Tyler on 4/16/17.
//  Copyright © 2017 Walkabout Apps. All rights reserved.
//

import UIKit
import MapKit
import Turf

enum MeasurementUnit: Int, Codable, CaseIterable {
    case miles, nauticalMiles, kilometers
    
    var displayString: String {
        switch self {
        case .miles:
            return "miles"
        case .nauticalMiles:
            return "nautical miles"
        case .kilometers:
            return "kilometers"
        }
    }
    
    var perMeter: Double {
        switch self {
        case .miles:
            return 0.000621371
        case .nauticalMiles:
            return 0.000539957
        case .kilometers:
            return 0.001
        }
    }
}

class MapDrawingVM: VM {
    let touchProximity: CGFloat = 22
    private weak var previousMapDelegate: MKMapViewDelegate?
    private let map: MKMapView
    private let onChange: ((DrawState.Drawing) -> Void)?
    private let onDone: (DrawState.Drawing) -> Void
    
    let drawSimplifiedArea: Bool
    let measurementUnit: MeasurementUnit
    var points = [CGPoint]()
    var coordinates = [CLLocationCoordinate2D]() {
        didSet { onChange?(.init(coordinates: coordinates)) }
    }
    var history = [[CLLocationCoordinate2D]]()
    
    var touchesInProgress = false
    private var appendToPathHead = false
    
    init(overMap map: MKMapView,
         drawSimplifiedArea: Bool,
         measurementUnit: MeasurementUnit,
         onChange: ((DrawState.Drawing) -> Void)?,
         onDone: @escaping (DrawState.Drawing) -> Void){
        self.map = map
        self.drawSimplifiedArea = drawSimplifiedArea
        self.measurementUnit = measurementUnit
        self.onChange = onChange
        self.onDone = onDone
        super.init()
        previousMapDelegate = map.delegate
        map.delegate = self
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    static func createMeasureDrawingView() -> MapDrawingUIView {
        return UINib(nibName: String(describing: MapDrawingUIView.self), bundle: nil).instantiate(withOwner: nil, options: nil).first as! MapDrawingUIView
    }
    
    func undo(){
        guard let previousCoordinates = history.popLast() else { return }
        coordinates = previousCoordinates
        points = coordinates.map { map.convert($0, toPointTo: map) }
        updateView()
    }
    
    func clear(){
        points.removeAll()
        coordinates.removeAll()
        history.removeAll()
        updateView()
    }
    
    func willDissapear() {
        map.delegate = previousMapDelegate
    }
    
    func exit(){
        map.delegate = previousMapDelegate
        onDone(.init(coordinates: coordinates))
    }
    
    //MARK: - Touch Handling
    func shouldHandleTouch(at point: CGPoint, event: UIEvent?) -> Bool {
        appendToPathHead = false
        guard touchesInProgress == false, let head = points.first, let tail = points.last  else { return true }
        if abs(point.x - tail.x) <= touchProximity && abs(point.y - tail.y) <= touchProximity {
            return true
        }
        else if abs(point.x - head.x) <= touchProximity && abs(point.y - head.y) <= touchProximity {
            appendToPathHead = true
            return true
        }
        return false
    }
    
    func touchesBegan(at point: CGPoint){
        touchesInProgress = true
        touchesContinue(at: [point])
        
        // add previous state to undo history
        history.append(coordinates)
    }
    
    func touchesContinue(at newPoints: [CGPoint]){
        var newCoordinates = newPoints.map({ map.convert($0, toCoordinateFrom: map) })
        if appendToPathHead{
            points = newPoints.reversed() + points
            newCoordinates.reverse()
            coordinates = newCoordinates + coordinates
        }
        else {
            points.append(contentsOf: newPoints)
            coordinates.append(contentsOf: newCoordinates)
        }
        updateView()
    }
    
    func touchesEnded(){
        touchesInProgress = false
        
        if drawSimplifiedArea {
            logger.log("Before count: \(coordinates.count)")
            let line = LineString(.init(coordinates: coordinates))
                .simplified(tolerance: min(map.region.span.longitudeDelta, map.region.span.latitudeDelta) / min(map.frame.width, map.frame.height) * 5)
            coordinates = line.coordinates
            points = coordinates.map { map.convert($0, toPointTo: map) }
            logger.log("Simplified count: \(coordinates.count)")
        }

        
        updateView()
    }
}

// MARK: - Utility
extension MapDrawingVM {
    
    var lenghthOfPathMeters: Double? {
        guard points.count >= 2 else { return nil }
        var meters: Double = 0
        for i in 1 ..< coordinates.count {
            meters += coordinates[i].metersFrom(coordinates[i-1])
        }
        return meters
    }
}

extension MapDrawingVM: MKMapViewDelegate {
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        points = coordinates.map({ map.convert($0, toPointTo: mapView) })
        updateView()
    }
    
}
