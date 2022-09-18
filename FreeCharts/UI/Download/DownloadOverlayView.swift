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
    @Binding var showNewDownloadOverlayView: Bool
    @Binding var mapRegion: MKCoordinateRegion
    @State var showNameField = false
    @State var name: String = ""
    
    @State private var geocoder: CLGeocoder?
            
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    Color.white.opacity(0.9)
                    RoundedRectangle(cornerRadius: 8)
                        .blendMode(.destinationOut)
                        .frame(width: geometry.size.width - 10,
                               height: geometry.size.height - 100 - getSafeArea().top - getSafeArea().bottom)
                }
                .compositingGroup()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }

            if showNameField {
                nameField
            } else {
                VStack(spacing: 0) {
                    Text("Choose an area to download")
                        .font(.title2)
                        .padding()
                    
                    Spacer()
                    
                    Button {
                        showNameField = true
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
    
    var nameField: some View {
        VStack {
            Spacer()
            VStack {
                Text("Name")
                Text("(optional)")
                    .font(.caption)
                    .foregroundColor(.gray)
                CustomTextField(text: $name, isFirstResponder: true)
                    .frame(height: 44)
                Button(action: {
                    downloadManager.createAndDownloadNewArea(region: mapRegion,
                                                             name: name == "" ? nil : name)
                    showNewDownloadOverlayView = false
                    showDownloadMenu = true
                }, label: {
                    Text("Download")
                        .font(.title2)
                        .padding()
                })
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .padding()
            
            Spacer()
        }
        .onAppear {
            geocoder = CLGeocoder()
            geocoder?.reverseGeocodeLocation(.init(latitude: mapRegion.center.latitude, longitude: mapRegion.center.longitude)) { places, error in
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
        Group {
            DownloadOverlayView(showDownloadMenu: .constant(false),
                                showNewDownloadOverlayView: .constant(false),
                                mapRegion: .constant(region))
            DownloadOverlayView(showDownloadMenu: .constant(false),
                                showNewDownloadOverlayView: .constant(false),
                                mapRegion: .constant(region),
                                showNameField: true)
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
