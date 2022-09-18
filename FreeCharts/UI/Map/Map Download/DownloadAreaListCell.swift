//
//  DownloadAreaListCell.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import SwiftUI

struct DownloadAreaListCell: View {
    
    let area: DownloadArea
    let index: Int
    
    @State var downloadProgress: Float?
    
    var manager = app.dependencies.downloadManager
    
    var body: some View {
        VStack {
            HStack {
                Text(area.name ?? "Area \(index)")
                    .padding()
                Spacer()
                if let size = area.sizeBytes {
                    Text("\(Float(size) / bytesInMB, specifier: "%.01f") MB")
                }
            }
            if let progress = downloadProgress {
                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
            }
        }
        .onReceive(manager.downloadProgressPublisher(area: area)) { downloadProgress = $0 }
    }
}

struct DownloadAreaListCell_Previews: PreviewProvider {
    static let region = MapRegion(center: .init(latitude: 1, longitude: 1),
                                  span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))

    static let area = DownloadArea(id: .init(), name: "Fish", region: region, status: .complete, sizeBytes: 13000000)
    static let area2 = DownloadArea(id: .init(), name: nil, region: region, status: .complete, sizeBytes: 1300000)
    static var previews: some View {
        Group {
            DownloadAreaListCell(area: area, index: 44)
            DownloadAreaListCell(area: area2, index: 45)
        }
    }
}
