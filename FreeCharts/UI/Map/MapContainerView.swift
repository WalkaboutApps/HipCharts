//
//  MapContainerView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import MapKit

struct MapContainerView: View {
    @SceneStorage("mapSceneState") var state = MapState()
    
    @State var userLocationTracking = UserLocationTracking.none
    @State var showDownloadMenu = false
    @State var showNewDownloadOverlay = false
    @State var showSettingsMenu = false
    @State var isLoadingCharts = true
    
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
            MapView(state: $state,
                    userLocationTracking: $userLocationTracking)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if !showNewDownloadOverlay {
                MapMenuView(state: $state,
                            showDownloadMenu: $showDownloadMenu,
                            showSettingsMenu: $showSettingsMenu,
                            showNewDownloadOverlayView: $showNewDownloadOverlay,
                            userLocationTracking: $userLocationTracking)
            }
            
            if showNewDownloadOverlay {
                DownloadOverlayView(showDownloadMenu: $showDownloadMenu,
                                    showNewDownloadOverlayView: $showNewDownloadOverlay,
                                    mapChangeEvent: $state.regionChangeEvent,
                                    chartOptions: state.options.chart)
            }
            
            if isLoadingCharts && state.options.map.showCharts {
                // show loader while charts load in background
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
            isLoadingCharts = !$0
        }
    }
}

struct MapContainerView_Previews: PreviewProvider {
    static var previews: some View {
        MapContainerView()
    }
}
