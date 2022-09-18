//
//  DownloadMenuView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import SwiftUI

let bytesInMB: Float = 1048576

struct DownloadMenuView: View {
    
    @Binding var showNewDownloadOverlay: Bool
    @Binding var showDownloadMenu: Bool
    @Binding var mapRegion: MapRegion
    
    @State var selection: UUID?
    
    var manager = app.dependencies.downloadManager
    
    @State var areas = [DownloadArea]()

    var body: some View {
        VStack(spacing: 0) {
            Text("Downloads")
                .font(.title)
                .padding()
            
            if areas.count == 0 {
                nullStateListView
            } else {
                areasListView
            }
            
            Button {
                showDownloadMenu = false
                showNewDownloadOverlay = true
            } label: {
                addImage
                    .padding()
            }
        }
        .onReceive(manager.downloadedAreas, perform: { areas = $0 })
    }
    
    var areasListView: some View {
        List(areas) { area in
            Button {
                mapRegion = area.region
                showDownloadMenu = false
            } label: {
                DownloadAreaListCell(area: area, index: areas.firstIndex { $0.id == area.id }!)
                    .foregroundColor(Color.black)
            }
            .buttonStyle(.plain)
        }
    }
    
    var nullStateListView: some View {
        List() {
            HStack {
                Spacer()
                Button {
                    showDownloadMenu = false
                    showNewDownloadOverlay = true
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
    static let region = MapRegion(center: .init(latitude: 1, longitude: 1),
                                  span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))

    static let area = DownloadArea(id: .init(), name: "Fish", region: region, status: .complete, sizeBytes: 13000000)
    static let area2 = DownloadArea(id: .init(), name: nil, region: region, status: .complete, sizeBytes: 1300000)

    static var previews: some View {
        Group {
            DownloadMenuView(showNewDownloadOverlay: .constant(true),
                             showDownloadMenu: .constant(true),
                             mapRegion: .constant(region))
            
            DownloadMenuView(showNewDownloadOverlay: .constant(true),
                             showDownloadMenu: .constant(true),
                             mapRegion: .constant(region),
                             areas: [area, area2])
        }
    }
}
