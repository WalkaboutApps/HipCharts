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
    let chartOptions: MapState.Options.Chart
    let onShowOnMap: () -> Void
    
    @State var downloadStatus: DownloadStatus?
    @State var errorText: String?
    
    var manager = app.dependencies.downloadManager
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Group {
                    Text(area.name ?? "Chart Area")
                    statusView
                    
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
                    
                    if let date = area.date {
                        Text("Updated \(dateFormatter.string(from: date))")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    
                    if case .downloading = downloadStatus {
                        Button {
                            manager.cancelDownload(area: area)
                        } label: {
                            Text("Cancel")
                                .foregroundColor(.accentColor)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            manager.download(area: area,
                                             chartOptions: chartOptions,
                                             refreshCachedFiles: downloadStatus?.isCompleted == true)
                        } label: {
                            Text("Update")
                                .foregroundColor(.accentColor)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if case .downloading(let progress) = downloadStatus {
                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
            }
        }
        .toast(message: $errorText)
        .onReceive(manager.downloadProgressPublisher(area: area)) { downloadStatus = $0 }
    }
    
    var statusView: some View {
        switch downloadStatus {
        case .downloading, .none:
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
                    errorText = errorString.displayString
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
    
    static let area = DownloadArea(id: .init(), name: "Fish That I saw once last winter, but is now gone", region: region, sizeBytes: 13000000)
    static let area2 = DownloadArea(id: .init(), name: nil, region: region, sizeBytes: 1300000)
    static var previews: some View {
        List {
            DownloadAreaListCell(area: area, chartOptions: .init(), onShowOnMap: { })
            DownloadAreaListCell(area: area2, chartOptions: .init(), onShowOnMap: { })
        }
    }
}
