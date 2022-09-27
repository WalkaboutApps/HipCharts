//
//  MapMenuView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import CoreLocation

struct MapMenuView: View {
    
    let showMenu: Bool
    @State var showMapTypeView = false
    @Binding var showCharts: Bool
    @Binding var baseMapType: MapType
    @Binding var showDownloadMenu: Bool
    @Binding var showSettingsMenu: Bool
    @Binding var showNewDownloadOverlayView: Bool
    @Binding var mapChangeEvent: MapRegionChangeEvent
    @Binding var userLocationTracking: UserLocationTracking
    
    let iconWidth: CGFloat = 22

    var body: some View {
        VStack(alignment: .trailing) {
            if showMapTypeView {
                mapTypeView
            }
            
            if showMenu {
                VStack(spacing: 0) {
                    
                    Button {
                        withAnimation {
                            requestLocationPermissionIfNeeded()
                            switch userLocationTracking {
                            case .none:
                                userLocationTracking = .follow
                            case .follow:
                                userLocationTracking = .followWithHeading
                            case .followWithHeading:
                                userLocationTracking = .follow
                            @unknown default:
                                userLocationTracking = .none
                            }
                        }
                    } label: {
                        Image(systemName: "location")
                            .resizable()
                            .frame(width: iconWidth, height: iconWidth)
                            .padding()
                    }
                    
//                    Button {
//                        showMapTypeView.toggle()
//                    } label: {
//                        Image(systemName: "square.3.layers.3d.down.left")
//                            .resizable()
//                            .frame(width: iconWidth, height: iconWidth)
//                            .padding()
//                    }
                    
                    NavigationLink(isActive: $showDownloadMenu) {
                        DownloadMenuView(showNewDownloadOverlay: $showNewDownloadOverlayView,
                                         showDownloadMenu: $showDownloadMenu,
                                         mapChangeEvent: $mapChangeEvent)
                    } label: {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .resizable()
                            .frame(width: iconWidth, height: iconWidth)
                            .padding()
                    }
                    
                    NavigationLink(isActive: $showSettingsMenu) {
                        MapSettingsMenuView(baseMapType: $baseMapType, showCharts: $showCharts)
                    } label: {
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: iconWidth, height: iconWidth)
                            .padding()
                    }
                    
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.systemBackground.opacity(0.7)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.systemBackground, lineWidth: 1)
                )
            }
        }
        .padding()
        .padding(.bottom)
        .animation(.easeInOut, value: 0.3)
    }
    
    var mapTypeView: some View {
        VStack(spacing: 0) {
            Button {
                showCharts.toggle()
                showMapTypeView.toggle()
            } label: {
                ZStack {
                    Image("map-type-chart")
                        .padding()
                        .opacity(0.6)
                    Image(systemName: showCharts ? "eye.slash" : "eye")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32)
                }
            }
            
            Button {
                baseMapType = .standard
                showMapTypeView.toggle()
            } label: {
                Image("map-type-standard")
                    .padding()
            }
            
            Button {
                baseMapType = .satellite
                showMapTypeView.toggle()
            } label: {
                Image("map-type-satellite")
                    .padding()
            }
        }
        .background(Color.systemBackground.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.systemBackground, lineWidth: 1)
        )
    }
}

func requestLocationPermissionIfNeeded() {
    let manager = CLLocationManager()
    if manager.authorizationStatus == .notDetermined {
        manager.requestWhenInUseAuthorization()
    }
}

//struct MapMenuView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapMenuView(mapType: , showDownloadView: <#Binding<Bool>#>)
//    }
//}
