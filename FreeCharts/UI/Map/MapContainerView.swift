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
    
    @AppStorage("chartFontSize") var chartFontSize = ChartFontSize.medium
    @SceneStorage("showCharts") var showChartsUserPreference = true
    @SceneStorage("baseMap") var baseMapType = MapType.standard
    @SceneStorage("mapRegion") var mapRegion: MapRegion = app.dependencies.defaults.codable(forKey: mapRegionDefaultsKey) ?? .init()
    
    @State var showCharts = false
    @State var showDownloadMenu = false
    @State var showNewDownloadOverlay = false
    @State var showSettingsMenu = false
    
    var defaults = app.dependencies.defaults
    var downloadManager = app.dependencies.downloadManager

    var body: some View {
        NavigationView {
            map
                .navigationBarHidden(true)
                .navigationTitle("Back")
        }
    }
    
    var map: some View {
        ZStack(alignment: .bottomTrailing) {
            MapView(showCharts: showCharts,
                    baseMap: baseMapType,
                    chartFontSize: chartFontSize,
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
                        showSettingsMenu: $showSettingsMenu,
                        showNewDownloadOverlayView: $showNewDownloadOverlay,
                        mapRegion: $mapRegion)
            
            if showNewDownloadOverlay {
                DownloadOverlayView(showDownloadMenu: $showDownloadMenu, mapRegion: $mapRegion)
            }
            
            if !showCharts && showChartsUserPreference {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .background(Color.black)
        .onReceive(downloadManager.cacheReady.dropFirst()) {
            showCharts = $0 && showChartsUserPreference
        }
    }
}

struct MapContainerView_Previews: PreviewProvider {
    static var previews: some View {
        MapContainerView()
    }
}
