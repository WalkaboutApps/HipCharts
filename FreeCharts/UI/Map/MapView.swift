//
//  MapView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import MapKit

typealias UserLocationTracking = MKUserTrackingMode
enum MapType: Int, Codable {
    case standard, satellite, hybrid, satelliteFlyover, hybridFlyover, mutedStandard
}

struct MapRegionChangeEvent: CodableAndRawRepresentable {
    enum Reason: Int, Codable { case map, app }
    let reason: Reason
    let region: MKCoordinateRegion
    var animated: Bool = false
}

struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView
    
    let showCharts: Bool
    let baseMap: MapType
    let chartTextSize: ChartTextSize
    @Binding var mapChangeEvent: MapRegionChangeEvent
    @Binding var userLocationTracking: UserLocationTracking
        
    func makeUIView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.region = mapChangeEvent.region
        view.showsUserLocation = true
        view.setCameraZoomRange(
            .init(minCenterCoordinateDistance: metersPerTileAtEquator(zoomLevel: ChartTileOverlay.maximumZ)
                 ),
            animated: false)
        view.delegate = context.coordinator
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        .init(mapChangeEvent: $mapChangeEvent, userLocationTracking: $userLocationTracking)
    }
    
    
    func updateUIView(_ view: MKMapView, context: Context) {
        // chart visibility
        let visibleChartOverlay = view.overlays.first(where: { $0 is ChartTileOverlay })
        if showCharts && visibleChartOverlay == nil {
            view.addOverlay(ChartTileOverlay(textSize: chartTextSize))
        } else if !showCharts, let overlay = visibleChartOverlay {
            view.removeOverlay(overlay)
        }
        
        if baseMap.mkMapType != view.mapType {
            view.mapType = baseMap.mkMapType
        }
        
        if mapChangeEvent.reason != .map, mapChangeEvent.region.span.latitudeDelta != 0 {
            view.setRegion(mapChangeEvent.region, animated: mapChangeEvent.animated)
        }
        
        if view.userTrackingMode != userLocationTracking {
            view.setUserTrackingMode(userLocationTracking, animated: true)
        }
    }
}

func metersPerTileAtEquator(zoomLevel: Int) -> CLLocationDistance {
    40075016.686 / pow(2, Double(zoomLevel - 3))
}

extension MapView {
    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var mapChangeEvent: MapRegionChangeEvent
        @Binding var userLocationTracking: UserLocationTracking
        
        init(mapChangeEvent: Binding<MapRegionChangeEvent>, userLocationTracking: Binding<UserLocationTracking>) {
            _mapChangeEvent = mapChangeEvent
            _userLocationTracking = userLocationTracking
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            MKTileOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if mapView.userTrackingMode != userLocationTracking {
                userLocationTracking = mapView.userTrackingMode
            }
            DispatchQueue.main.async {
                self.mapChangeEvent = .init(reason: .map, region: mapView.region)
            }
        }
    }
}

extension MapType {
    var mkMapType: MKMapType {
        switch self {
        case .standard:
            return .standard
        case .satellite:
            return .satellite
        case .hybrid:
            return .hybrid
        case .satelliteFlyover:
            return .satelliteFlyover
        case .hybridFlyover:
            return .hybridFlyover
        case .mutedStandard:
            return .mutedStandard
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(showCharts: true,
                baseMap: .standard,
                chartTextSize: .medium,
                mapChangeEvent: .constant(.init(reason: .map, region: .init())),
                userLocationTracking: .constant(.none))
    }
}
