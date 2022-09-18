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
    
    var body: some View {
        Form {
            Toggle("Show Charts", isOn: $showCharts)
            
            VStack(alignment: .leading) {
                Text("Base Map Style")
                Picker("Base Map Style", selection: $baseMapType) {
                    ForEach([MapType.standard, MapType.satellite, MapType.hybrid], id: \.rawValue) { baseMap in
                        Text(baseMap.displayString).tag(baseMap)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
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
