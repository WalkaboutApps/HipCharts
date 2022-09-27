//
//  MapContainerView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import MapKit

struct MapContainerView: View {
    
    @AppStorage("chartTextSize") var chartTextSize = ChartTextSize.medium
    @SceneStorage("showCharts") var showChartsUserPreference = true
    @SceneStorage("baseMap") var baseMapType = MapType.standard
    @SceneStorage("mapChangeEvent") var mapChangeEvent = MapRegionChangeEvent(reason: .app, region: .init())
    
    @State var showCharts = false
    @State var userLocationTracking = UserLocationTracking.none
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
                    chartTextSize: chartTextSize,
                    mapChangeEvent: $mapChangeEvent,
                    userLocationTracking: $userLocationTracking)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            MapMenuView(showMenu: !showNewDownloadOverlay,
                        showCharts: $showCharts,
                        baseMapType: $baseMapType,
                        showDownloadMenu: $showDownloadMenu,
                        showSettingsMenu: $showSettingsMenu,
                        showNewDownloadOverlayView: $showNewDownloadOverlay,
                        mapChangeEvent: $mapChangeEvent,
                        userLocationTracking: $userLocationTracking)
            
            if showNewDownloadOverlay {
                DownloadOverlayView(showDownloadMenu: $showDownloadMenu,
                                    showNewDownloadOverlayView: $showNewDownloadOverlay,
                                    mapChangeEvent: $mapChangeEvent)
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
