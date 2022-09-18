//
//  MapContainerView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import MapKit

private let mapRegionDefaultsKey = "MapRegion"

struct MapContainerView: View {
    
    // TODO: Store map type choice and restore on launch
    @State var showCharts = false
    @State var baseMapType = MKMapType.standard
    @State var mapRegion: MapRegion = app.dependencies.defaults.codable(forKey: mapRegionDefaultsKey) ?? .init()
    @State var showDownloadMenu = false
    @State var showNewDownloadOverlay = false
    @State var showSettingsMenu = false
    
    var defaults = app.dependencies.defaults
    var downloadManager = app.dependencies.downloadManager

    var body: some View {
        if showDownloadMenu {
            DownloadMenuView(showNewDownloadOverlay: $showNewDownloadOverlay,
                             showDownloadMenu: $showDownloadMenu,
                             mapRegion: $mapRegion)
        } else {
            map
        }
    }
    
    var map: some View {
        ZStack(alignment: .bottomTrailing) {
            MapView(showCharts: showCharts,
                    baseMap: baseMapType,
                    mapRegion: Binding(get: { mapRegion },
                                       set: {
                defaults.setCodable(mapRegion, forKey: mapRegionDefaultsKey)
                mapRegion = $0
            }))
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            MapMenuView(showMenu: !showNewDownloadOverlay,
                        showCharts: $showCharts,
                        baseMapType: $baseMapType,
                        showDownloadMenu: $showDownloadMenu,
                        showSettingsMenu: $showSettingsMenu)
            
            if showNewDownloadOverlay {
                DownloadOverlayView(showDownloadMenu: $showDownloadMenu, mapRegion: $mapRegion)
            }
        }
        .background(Color.black)
        .onReceive(downloadManager.cacheReady.dropFirst()) { showCharts = $0 }
    }
}

struct MapContainerView_Previews: PreviewProvider {
    static var previews: some View {
        MapContainerView()
    }
}
