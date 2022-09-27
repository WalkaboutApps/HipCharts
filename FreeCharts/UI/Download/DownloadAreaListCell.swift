//
//  DownloadAreaListCell.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import SwiftUI
import MapKit

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .short
    return f
}()

struct DownloadAreaListCell: View {
    
    let area: DownloadArea
    let index: Int
    let onShowOnMap: () -> Void
    
    @State var downloadProgress: Float?
    @State var errorText: String?
    
    var manager = app.dependencies.downloadManager
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Group {
                    Text(area.name ?? "Area \(index)")
                    statusView(area.status)

                    Spacer()
                }
                .background(Color.systemBackground)
                .onTapGesture(perform: onShowOnMap)
                
                VStack(alignment: .trailing, spacing: 0) {
                    
                    if let size = area.sizeBytes {
                        Text("\(Float(size) / bytesInMB, specifier: "%.01f") MB")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    
                        Text("Updated \(dateFormatter.string(from: .init()))")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)

                    
                        
                        Button {
                            manager.download(area: area)
                            downloadProgress = 0
                        } label: {
                            Text("Update")
                                .foregroundColor(.accentColor)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                }
                
            }
            if let progress = downloadProgress {
                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
            }
        }
        .toast(message: $errorText)
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
                        .background(Color.systemBackground)
                })
                .buttonStyle(.plain)
                .foregroundColor(.orange)
            )
        }
    }
}

struct DownloadAreaListCell_Previews: PreviewProvider {
    static let region = MKCoordinateRegion(center: .init(latitude: 1, longitude: 1),
                                  span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))

    static let area = DownloadArea(id: .init(), name: "Fish That I saw once last winter, but is now gone", region: region, status: .complete, sizeBytes: 13000000)
    static let area2 = DownloadArea(id: .init(), name: nil, region: region, status: .complete, sizeBytes: 1300000)
    static var previews: some View {
        List {
            DownloadAreaListCell(area: area, index: 44, onShowOnMap: { })
            DownloadAreaListCell(area: area2, index: 45, onShowOnMap: { })
        }
    }
}
