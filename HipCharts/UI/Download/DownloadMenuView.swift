//
//  DownloadMenuView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Combine
import SwiftUI

let bytesInMB: Float = 1048576

struct DownloadMenuView: View {
    
    @Binding var showNewDownloadOverlay: Bool
    @Binding var showDownloadMenu: Bool
    @Binding var mapChangeEvent: MapRegionChangeEvent
    @Binding var showPaywall: Bool
    let chartOptions: ChartOptions
    
    @State var selection: UUID?
    
    var manager = app.dependencies.downloadManager
    
    @State var areas = [DownloadArea]()
    @State var cancellables = CancellableSet()
    @State var isLoading = false
    @State var errorText: String?
    
    var body: some View {
        VStack(spacing: 0) {
            if areas.count == 0 {
                nullStateListView
            } else {
                areasListView
            }
            
            Button {
                if app.dependencies.paymentManager.hasAccessToPaidFeature(.download) {
                    showDownloadMenu = false
                    showNewDownloadOverlay = true
                } else {
                    showPaywall = true
                }
            } label: {
                addImage
                    .padding()
            }
        }
        .overlay(Group { if isLoading { ProgressView() } })
        .onReceive(manager.downloadedAreas, perform: { areas = $0 })
        .onReceive(manager.cacheReady) { isLoading = !$0 }
        .navigationTitle("Downloads")
    }
    
    var areasListView: some View {
        List() {
            ForEach(areas) { area in
                DownloadAreaListCell(area: area,
                                     chartOptions: chartOptions) {
                    mapChangeEvent = .init(reason: .app, region: area.customPolygon?.region ?? area.region)
                    showDownloadMenu = false
                }
            }
            .onDelete { index in
                guard let i = index.first else { return }
                isLoading = true
                manager.deleteDownload(area: areas[i])
                    .sink { completion in
                        if case .failure(let error) = completion {
                            errorText = error.displayString
                        }
                        isLoading = false
                    } receiveValue: { }
                    .store(in: &cancellables)
            }
        }
    }
    
    var nullStateListView: some View {
        List() {
            HStack {
                Spacer()
                Button {
                    if app.dependencies.paymentManager.hasAccessToPaidFeature(.download) {
                        showDownloadMenu = false
                        showNewDownloadOverlay = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    VStack {
                        Text("Download charts for offline use")
                        addImage
                    }
                }
                Spacer()
            }
        }
    }
    
    var addImage: some View {
        Image(systemName: "plus.circle")
            .resizable()
            .frame(width: 32, height: 32)
    }
}

extension DownloadArea: Identifiable { }

struct DownloadMenuView_Previews: PreviewProvider {
    static let mapChangeEvent = MapRegionChangeEvent(reason: .map,
                                                     region: .init(center: .init(latitude: 1, longitude: 1),
                                                                   span: .init(latitudeDelta: 0.01,
                                                                               longitudeDelta: 0.01)))

    static let area = DownloadArea(id: .init(), name: "Fish", region: mapChangeEvent.region, sizeBytes: 13000000)
    static let area2 = DownloadArea(id: .init(), name: nil, region: mapChangeEvent.region, sizeBytes: 1300000)

    static var previews: some View {
        Group {
            DownloadMenuView(showNewDownloadOverlay: .constant(true),
                             showDownloadMenu: .constant(true),
                             mapChangeEvent: .constant(mapChangeEvent),
                             showPaywall: .constant(false),
                             chartOptions: .init())
            
            DownloadMenuView(showNewDownloadOverlay: .constant(true),
                             showDownloadMenu: .constant(true),
                             mapChangeEvent: .constant(mapChangeEvent),
                             showPaywall: .constant(false),
                             chartOptions: .init(),
                             areas: [area, area2])
        }
    }
}
