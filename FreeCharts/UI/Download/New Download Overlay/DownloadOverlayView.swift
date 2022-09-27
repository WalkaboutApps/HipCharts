//
//  DownloadOverlayView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/16/22.
//

import SwiftUI
import MapKit

let bytesInAGb: Float = 1073741824
private let averageFileSizeBytes: Float = 1000

struct DownloadOverlayView: View {
    
    var downloadManager = app.dependencies.downloadManager
    
    @Binding var showDownloadMenu: Bool
    @Binding var showNewDownloadOverlayView: Bool
    @Binding var mapChangeEvent: MapRegionChangeEvent
    let chartOptions: MapState.Options.Chart
    @State var showNameField = false
    @State var name: String = ""
    
    @State private var geocoder: CLGeocoder?
            
    var body: some View {
        ZStack {
            if showNameField {
                nameField
            } else {
                VStack {
                    
                    Text("Choose an area to download")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding()
                        .background(Color.systemBackground.opacity(0.8))
                        .cornerRadius(8)
                    
                    backButton
                    
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Button {
                            showNameField = true
                        } label: {
                            Text("Download")
                                .font(.title2)
                        }
                        
                        Text(estimatedSizeText)
                    }
                    .padding()
                    .background(Color.systemBackground.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.bottom)

                }
            }
        }
        .animation(.easeInOut, value: 0.3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var estimatedSizeText: String {
        let tileCount = estimatedDownloadTileCount(region: mapChangeEvent.region)
        let sizeBytes = Float(tileCount) * averageFileSizeBytes
        let size = sizeBytes > bytesInAGb ? Float(sizeBytes) / bytesInAGb : Float(sizeBytes) / bytesInMB
        let unit = sizeBytes > bytesInAGb ? "gb" : "mb"

        return "~\(tileCount) tiles, ~\(String(format: "%.1f", size)) \(unit)"
    }
    
    var backButton: some View {
        HStack {
            Button {
                showNewDownloadOverlayView.toggle()
            } label: {
                Image(systemName: "chevron.left")
                    .padding()
                    .background(Circle().fill(Color.systemBackground.opacity(0.8))
                        )
            }
            Spacer()
        }
        .padding(.horizontal)
        .id("back button")
    }
    
    var nameField: some View {
        VStack {
            backButton
            Spacer()
            VStack {
                Text("Name")
                Text("(optional)")
                    .font(.caption)
                    .foregroundColor(.gray)
                CustomTextField(text: $name, isFirstResponder: true)
                    .frame(height: 44)
                Button(action: {
                    showNewDownloadOverlayView = false
                    showDownloadMenu = true
                    downloadManager.createAndDownloadNewArea(region: mapChangeEvent.region,
                                                             name: name == "" ? nil : name,
                                                             chartOptions: chartOptions)
                }, label: {
                    Text("Download")
                        .font(.title2)
                        .padding()
                })
            }
            .padding()
            .background(Color.systemBackground)
            .cornerRadius(8)
            .padding()
            
            Spacer()
        }
        .onAppear {
            geocoder = CLGeocoder()
            geocoder?.reverseGeocodeLocation(.init(latitude: mapChangeEvent.region.center.latitude,
                                                   longitude: mapChangeEvent.region.center.longitude)) { places, error in
                if let match = places?.first, name == "" {
                    name = match.locality ?? match.country ?? match.inlandWater ?? match.ocean ?? ""
                }
            }
        }
    }
}

func estimatedDownloadTileCount(region: MKCoordinateRegion) -> Int {
    var count = 0
    (ChartTileOverlay.minimumZ ... ChartTileOverlay.maximumZ).forEach { zoomLevel in
        let degreesPerTile = 360 / powf(2, Float(zoomLevel))
        let width = Int(ceil(Float(region.span.longitudeDelta) / degreesPerTile)) + 1
        let height = Int(ceil(Float(region.span.latitudeDelta) / degreesPerTile)) + 1
        count += width * height
        logger.log("\(width * height) tiles in zoom level \(zoomLevel). ~\(Float(width * height) * averageFileSizeBytes / bytesInMB) mb")
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
    static let mapChangeEvent = MapRegionChangeEvent(reason: .app,
                                                     region: MKCoordinateRegion(center: .init(latitude: 1, longitude: 1),
                                                                                span: .init(latitudeDelta: 0.01,
                                                                                            longitudeDelta: 0.01)))
    static var previews: some View {
        Group {
            DownloadOverlayView(showDownloadMenu: .constant(false),
                                showNewDownloadOverlayView: .constant(false),
                                mapChangeEvent: .constant(mapChangeEvent),
                                chartOptions: .init())
            DownloadOverlayView(showDownloadMenu: .constant(false),
                                showNewDownloadOverlayView: .constant(false),
                                mapChangeEvent: .constant(mapChangeEvent),
                                chartOptions: .init(), showNameField: true)
        }
        .background(Color.yellow)
    }
}


struct CustomTextField: UIViewRepresentable {

    class Coordinator: NSObject, UITextFieldDelegate {

        @Binding var text: String
        var didBecomeFirstResponder = false

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

    }

    @Binding var text: String
    var isFirstResponder: Bool = false

    func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        return textField
    }

    func makeCoordinator() -> CustomTextField.Coordinator {
        return Coordinator(text: $text)
    }

    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<CustomTextField>) {
        uiView.text = text
        if isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        }
    }
}
