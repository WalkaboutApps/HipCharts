//
//  PaywallView.swift
//  HipCharts
//
//  Created by Fish Sticks on 10/2/22.
//

import SwiftUI

struct PaywallView: View {
    
    @Binding var showPaywall: Bool
    @State var pricingText: String?
    
    var body: some View {
        ZStack {
            Color.label.opacity(0.3)
                .ignoresSafeArea()
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(Color.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.systemBackground, lineWidth: 1)
                )
                .padding()
        }
    }
    
    var content: some View {
        VStack(alignment: .leading) {
            backButton
            HStack {
                Spacer(minLength: 0)
                VStack {
                    Image("LaunchImage")
                        .padding()
                    Text("Please Subscribe")
                        .font(.title)
                }
                Spacer(minLength: 0)
            }
            Spacer().frame(height: 20)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Help us keep the lights on with a super-cheap monthly subscription. Subscribers gain access to the following features:")
                ForEach(PaidFeature.allCases, id: \.rawValue) {
                    Text("• " + $0.displayDescription)
                }
            }
            
            Spacer()
            HStack {
                Spacer()
                subscribeButton
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
    
    var backButton: some View {
        HStack {
            Button {
                showPaywall = false
            } label: {
                Image(systemName: "chevron.left")
                    .padding()
            }
            Spacer()
        }
        .id("back button")
    }
    
    var subscribeButton: some View {
        VStack {
            if let pricingText = pricingText {
                Button {
                    
                } label: {
                    Text("Subscribe")
                        .padding()
                        .foregroundColor(.lightText)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.systemBackground, lineWidth: 1)
                        )
                }
                Text(pricingText)
            } else {
                ProgressView()
            }
        }
    }
}

extension PaidFeature {
    var displayDescription: String {
        switch self {
        case .download:
            return "Download charts for offline use."
        case .polygonDownload:
            return "Draw custom boundaries when downloading charts. (Saves space and download time by downloading exactly the areas you specify and no more)."
        case .drawRoute:
            return "Plot and manage routes (coming soon)"
        }
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaywallView(showPaywall: .constant(true),
                        pricingText: "$1 monthly")
            PaywallView(showPaywall: .constant(true))
        }
    }
}
