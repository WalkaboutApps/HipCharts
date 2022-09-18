//
//  MapMenuView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import MapKit

struct MapMenuView: View {
    
    let showMenu: Bool
    @State var showMapTypeView = false
    @Binding var showCharts: Bool
    @Binding var baseMapType: MKMapType
    @Binding var showDownloadMenu: Bool
    @Binding var showSettingsMenu: Bool
    
    var body: some View {
        VStack {
            if showMapTypeView {
                mapTypeView
            }
            
            if showMenu {
                VStack(spacing: 0) {
                    Button {
                        showMapTypeView.toggle()
                    } label: {
                        Image(systemName: "square.3.layers.3d.down.right")
                            .padding()
                    }
                    
                    Button {
                        showDownloadMenu.toggle()
                    } label: {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .padding()
                    }
                    
                    Button {
                        showSettingsMenu.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                            .padding()
                    }
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.7)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1)
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
                Text("C")
                    .padding()
            }
            
            Button {
                baseMapType = .standard
                showMapTypeView.toggle()
            } label: {
                Text("S")
                    .padding()
            }
            
            Button {
                baseMapType = .satellite
                showMapTypeView.toggle()
            } label: {
                Text("S")
                    .padding()
            }
        }
        .background(Color.white.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 1)
        )
    }
}

//struct MapMenuView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapMenuView(mapType: , showDownloadView: <#Binding<Bool>#>)
//    }
//}
