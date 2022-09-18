//
//  MapView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import MapKit

typealias MapRegion = MKCoordinateRegion

struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView
    
    let showCharts: Bool
    let baseMap: MKMapType
    @Binding var mapRegion: MapRegion
        
    func makeUIView(context: Context) -> MKMapView {
        let view = MKMapView()
        view.delegate = context.coordinator
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        .init(mapRegion: $mapRegion)
    }
    
    
    func updateUIView(_ view: MKMapView, context: Context) {
        // chart visibility
        let visibleChartOverlay = view.overlays.first(where: { $0 is ChartTileOverlay })
        if showCharts && visibleChartOverlay == nil {
            view.addOverlay(ChartTileOverlay())
        } else if !showCharts, let overlay = visibleChartOverlay {
            view.removeOverlay(overlay)
        }
        
        view.mapType = baseMap
        view.setCameraZoomRange(
            .init(minCenterCoordinateDistance: metersPerTileAtEquator(zoomLevel: ChartTileOverlay.maximumZ)
                 ),
            animated: false)
        if mapRegion.span.latitudeDelta != 0 {
            view.region = mapRegion
        }
    }
}

func metersPerTileAtEquator(zoomLevel: Int) -> CLLocationDistance {
    40075016.686 / pow(2, Double(zoomLevel - 3))
}

extension MapView {
    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var mapRegion: MapRegion
        
        init(mapRegion: Binding<MapRegion>) {
            _mapRegion = mapRegion
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            MKTileOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            mapRegion = mapView.region
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(showCharts: true, baseMap: .standard, mapRegion: .constant(.init()))
    }
}
