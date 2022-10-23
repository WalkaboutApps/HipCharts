//
//  PaywallView.swift
//  HipCharts
//
//  Created by Fish Sticks on 10/2/22.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    
    @Binding var showPaywall: Bool
    @State var product: Product?
    @State var isPurchased = false
    @State var errorTitle: String?
    
    var pricingManager: PricingManager = app.dependencies.pricingManager
    
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
        VStack {
            backButton
            List {
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
                .listRowSeparator(.hidden)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Help us keep the lights on with a super-cheap monthly subscription. Subscribers gain access to the following features:")
                    ForEach(PaidFeature.allCases, id: \.rawValue) {
                        Text("• " + $0.displayDescription)
                    }
                }
                .multilineTextAlignment(.leading)
                .lineLimit(10)
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)

                if let errorTitle = errorTitle {
                    HStack {
                        Spacer(minLength: 0)
                        Text(errorTitle)
                        Spacer(minLength: 0)
                    }
                    .listRowSeparator(.hidden)
                } else {
                    SubscriptionsSectionView(showSectionTitle: false)
                        .listRowSeparator(.hidden)
                }
                
            }
        }
        .listStyle(.plain)
    }
    
    var backButton: some View {
        HStack {
            Button {
                showPaywall = false
            } label: {
                Image(systemName: "chevron.left")
                    .padding()
                    .padding(.top)
                    .padding(.leading)
            }
            Spacer()
        }
        .id("back button")
    }
}

extension PaidFeature {
    var displayDescription: String {
        switch self {
        case .download:
            return "Download charts for offline use."
        case .polygonDownload:
            return "Draw custom boundaries when downloading charts. (Saves space and download time by downloading exactly the areas you specify)."
        case .drawRoute:
            return "Plot and manage routes (coming soon)"
        }
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaywallView(showPaywall: .constant(true))
        }
    }
}

