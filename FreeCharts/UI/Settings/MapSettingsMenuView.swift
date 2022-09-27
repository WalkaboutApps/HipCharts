//
//  MapSettingsView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/18/22.
//

import SwiftUI

struct MapSettingsMenuView: View {
    
    @Binding var baseMapType: MapType
    @Binding var showCharts: Bool
    @AppStorage("chartTextSize") var chartTextSize = ChartTextSize.medium
    
    var body: some View {
        Form {
            Section(header: Text("Map Appearance")) {
                Toggle("Show Charts", isOn: $showCharts)
                
                VStack(alignment: .leading) {
                    Text("Base Map Style")
                    Picker("Base Map Style", selection: $baseMapType) {
                        ForEach([MapType.standard, MapType.satellite, MapType.hybrid], id: \.rawValue) {
                            Text($0.displayString).tag($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            Section(header: Text("Charts")) {
                VStack(alignment: .leading) {
                    Text("Chart Text Size")
                    Picker("Chart Text Size", selection: $chartTextSize) {
                        ForEach(ChartTextSize.allCases, id: \.rawValue) {
                            Text($0.displayString).tag($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Text("* To apply this value to previously downloaded charts, tap the \"Update\" buttons in the Chart Download page")
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(20)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct MapSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MapSettingsMenuView(baseMapType: .constant(.standard), showCharts: .constant(true))
    }
}

extension MapType {
    var displayString: String {
        switch self {
        case .standard:
            return "Standard"
        case .satellite:
            return "Satellite"
        case .hybrid:
            return "Hybrid"
        case .satelliteFlyover:
            return "Satellite Flyover"
        case .hybridFlyover:
            return "Hybrid Flyover"
        case .mutedStandard:
            return "Muted Standard"
        }
    }
}

extension ChartTextSize {
    var displayString: String {
        switch self {
        case .large:
            return "Large"
        case .medium:
            return "Medium"
        case .small:
            return "Small"
        }
    }
}
