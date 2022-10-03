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

struct DrawState {
    struct Drawing {
        let coordinates: [CLLocationCoordinate2D]
    }
    var initial: Drawing? = nil
    var drawArea: Bool = false
    var onChange: ((Drawing) -> Void)? = nil
    let onComplete: (Drawing) -> Void
}

struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView
    
    @Binding var state: MapState
    @Binding var userLocationTracking: UserLocationTracking
    let showDrawing: DrawState?
        
    func makeUIView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.region = state.regionChangeEvent.region
        view.showsUserLocation = true
        view.setCameraZoomRange(
            .init(minCenterCoordinateDistance: metersPerTileAtEquator(zoomLevel: ChartTileOverlay.maximumZ)
                 ),
            animated: false)
        view.delegate = context.coordinator
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        .init(mapChangeEvent: $state.regionChangeEvent, userLocationTracking: $userLocationTracking)
    }
    
    
    func updateUIView(_ view: MKMapView, context: Context) {
        // chart visibility
        let visibleChartOverlay = view.overlays.first(where: { $0 is ChartTileOverlay }) as? ChartTileOverlay
        if state.options.map.showCharts && visibleChartOverlay == nil {
            view.addOverlay(ChartTileOverlay(options: state.options.chart))
        } else if state.options.map.showCharts,
                  let overlay = visibleChartOverlay,
                  state.options.chart != overlay.options {
            view.removeOverlay(overlay)
            view.addOverlay(ChartTileOverlay(options: state.options.chart))
        } else if !state.options.map.showCharts, let overlay = visibleChartOverlay {
            view.removeOverlay(overlay)
        }
        
        if state.options.map.baseMap.mkMapType != view.mapType {
            view.mapType = state.options.map.baseMap.mkMapType
        }
        
        if state.regionChangeEvent.reason != .map, state.regionChangeEvent.region.span.latitudeDelta != 0 {
            view.setRegion(state.regionChangeEvent.region, animated: state.regionChangeEvent.animated)
        }
        
        if view.userTrackingMode != userLocationTracking {
            view.setUserTrackingMode(userLocationTracking, animated: true)
        }
        
        // drawing overlay UI View
        let visibleDrawingView = view.subviews.first(where: { $0 is MapDrawingUIView }) as? MapDrawingUIView
        if let drawingState = showDrawing,  visibleDrawingView == nil {
            let vm = MapDrawingVM(overMap: view,
                                  drawSimplifiedArea: drawingState.drawArea,
                                  measurementUnit: state.options.map.measurementUnit,
                                  onChange: drawingState.onChange,
                                  onDone: drawingState.onComplete)
            vm.coordinates = drawingState.initial?.coordinates ?? []
            let drawingView = MapDrawingVM.createMeasureDrawingView()
            drawingView.bind(to: vm)
            view.addSubviewStretchedToBounds(drawingView)
        } else if showDrawing == nil, let visible = visibleDrawingView {
            visible.removeFromSuperview()
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
            MapView(state: .constant(.init()),
                    userLocationTracking: .constant(.none),
                    showDrawing: .init(initial: .init(coordinates: [
                        .init(latitude: 0, longitude: 0),
                        .init(latitude: 30, longitude: 50),
                        .init(latitude: 30, longitude: -50),
                        .init(latitude: -40, longitude: -50)
                    ]), onComplete: { _ in }))
    }
}
