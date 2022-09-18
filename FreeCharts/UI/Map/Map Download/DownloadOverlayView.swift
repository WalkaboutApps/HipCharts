//
//  DownloadOverlayView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import MapKit

private let averageFileSizeBytes: Float = 9436.467

struct DownloadOverlayView: View {
    
    var downloadManager = app.dependencies.downloadManager
    
    @Binding var showDownloadMenu: Bool
    @Binding var mapRegion: MKCoordinateRegion
        
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    Color.white.opacity(0.5)
                    RoundedRectangle(cornerRadius: 8)
                        .blendMode(.destinationOut)
                        .frame(width: geometry.size.width - 10,
                               height: geometry.size.height - 120 - getSafeArea().top - getSafeArea().bottom)
                }
                .compositingGroup()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }

            
            VStack(spacing: 0) {
                Text("Choose an area to download")
                    .padding()
                
                Spacer()
                
                Button {
                    downloadManager.download(region: mapRegion)
                    showDownloadMenu = true
                } label: {
                    Text("Download")
                        .font(.title2)
                }
                
                Text("~\(estimatedDownloadTileCount(region: mapRegion)) tiles, ~\(Float(estimatedDownloadTileCount(region: mapRegion)) * averageFileSizeBytes / bytesInMB, specifier: "%.0f") MB")
                    .padding(.top, 4)
            }
            .padding(.bottom)

        }
    }
}

private let sharedOverlay = ChartTileOverlay()
func estimatedDownloadTileCount(region: MKCoordinateRegion) -> Int {
    var count = 0
    (ChartTileOverlay.minimumZ ... ChartTileOverlay.maximumZ).forEach { zoomLevel in
        let degreesPerTile = 360 / powf(2, Float(zoomLevel))
        let width = Int(ceil(Float(region.span.longitudeDelta) / degreesPerTile)) + 1
        let height = Int(ceil(Float(region.span.latitudeDelta) / degreesPerTile)) + 1
        count += width * height
    }
    return count
}

func getSafeArea() -> UIEdgeInsets {
    let keyWindow = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first
    return (keyWindow?.safeAreaInsets)!
}

struct DownloadOverlayView_Previews: PreviewProvider {
    static let region = MKCoordinateRegion(center: .init(latitude: 1, longitude: 1),
                                    span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
    static var previews: some View {
        DownloadOverlayView(showDownloadMenu: .constant(true), mapRegion: .constant(region))
    }
}
