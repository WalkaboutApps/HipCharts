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
    @State var errorText: String?
    
    var manager = app.dependencies.downloadManager
    
    var body: some View {
        VStack {
            HStack {
                Text(area.name ?? "Area \(index)")
                    .padding()
                Spacer()
                if let size = area.sizeBytes {
                    Text("\(Float(size) / bytesInMB, specifier: "%.01f") MB")
                        .foregroundColor(Color.black)
                }
                statusView(area.status)
            }
            if let progress = downloadProgress {
                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
            }
        }
        .onReceive(manager.downloadProgressPublisher(area: area)) { downloadProgress = $0 }
    }
    
    func statusView(_ status: DownloadArea.Status) -> some View {
        switch status {
        case .downloading:
            return AnyView(EmptyView())
        case .complete:
            return AnyView(
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .padding()
            )
        case .failed(errorString: let errorString):
            return AnyView(
                Button(action: {
                    errorText = errorString
                }, label: {
                    Image(systemName: "exclamationmark.triangle")
                        .padding()
                })
                .foregroundColor(.orange)
                .toast(message: $errorText)
            )
        }
    }
}

struct DownloadAreaListCell_Previews: PreviewProvider {
    static let region = MapRegion(center: .init(latitude: 1, longitude: 1),
                                  span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))

    static let area = DownloadArea(id: .init(), name: "Fish", region: region, status: .complete, sizeBytes: 13000000)
    static let area2 = DownloadArea(id: .init(), name: nil, region: region, status: .complete, sizeBytes: 1300000)
    static var previews: some View {
        List {
            Button(action: {}) {
                DownloadAreaListCell(area: area, index: 44)
            }
            Button(action: {}) {
                DownloadAreaListCell(area: area2, index: 45)
            }
        }
    }
}
