//
//  MapSettingsView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/18/22.
//

import SwiftUI

struct MapSettingsMenuView: View {
    
    @Binding var options: MapState.Options
        
    var body: some View {
        Form {
            Section(header: Text("Map Appearance")) {
                Toggle("Show Charts", isOn: $options.map.showCharts)
                                
                VStack(alignment: .leading) {
                    Text("Base Map Style")
                    Picker("Base Map Style", selection: $options.map.baseMap) {
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
                    Picker("Chart Text Size", selection: $options.chart.textSize) {
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
                
                Toggle("Show Areas and Limits", isOn: $options.chart.showChartAreasAndLimits)
                
                VStack(alignment: .leading) {
                    Toggle("Retina Quality Charts", isOn: $options.chart.highQuality)
                    Text("* Retina files are 4 times larger")
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
        MapSettingsMenuView(options: .constant(.init()))
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
