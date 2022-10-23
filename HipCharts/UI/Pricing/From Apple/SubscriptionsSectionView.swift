/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view in the store for subscription products that also displays subscription statuses.
*/

import StoreKit
import SwiftUI

struct SubscriptionsSectionView: View {
    @Environment(\.openURL) var openURL
    
    var showSectionTitle: Bool = true

    @State var subscription: Product?
    @State var purchasedSubscription: Product?
    @State var status: Product.SubscriptionInfo.Status?
    
    var pricingManager: PricingManager = app.dependencies.pricingManager

    var body: some View {
        Group {
            if let currentSubscription = purchasedSubscription {
                Section(showSectionTitle ? "My Subscription" : "") {
                   ListCellView(product: currentSubscription)

                    if let status = status {
                        StatusInfoView(product: currentSubscription,
                                        status: status)
                    }
                }
            } else if let subscription = subscription {
                Section(showSectionTitle ? "Subscribe" : "") {
                    ListCellView(product: subscription)
                    
                    Button(action: {
                        Task {
                            //This call displays a system prompt that asks users to authenticate with their App Store credentials.
                            //Call this function only in response to an explicit user action, such as tapping a button.
                            try? await AppStore.sync()
                        }
                    }, label: {
                        Text("Restore Purchases")
                            .foregroundColor(Color.accentColor)
                    })
                    .buttonStyle(.plain)
                    
                    HStack {
                        Button {
                            openURL(URL(string: "https://walkaboutapps.wixsite.com/apps/privacy")!)
                        } label: {
                            Text("Privacy")
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        Text("&")
                        Button {
                            openURL(URL(string: "https://walkaboutapps.wixsite.com/apps/terms-of-use")!)
                        } label: {
                            Text("Terms of Use")
                                .foregroundColor(Color.accentColor)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                //When this view appears, get the latest subscription status.
                await updateSubscriptionStatus()
            }
        }
        .onReceive(pricingManager.purchasedSubscriptionProduct) { _ in
            Task {
                // purchases change, get the latest subscription status.
                await updateSubscriptionStatus()
            }
        }
        .onReceive(pricingManager.subscriptionProduct) { subscription in
            if subscription != nil {
                self.subscription = subscription
                Task {
                    //When `purchasedSubscriptions` changes, get the latest subscription status.
                    await updateSubscriptionStatus()
                }
            }
        }
        
    }

    @MainActor
    func updateSubscriptionStatus() async {
        do {
            //This app has only one subscription group, so products in the subscriptions
            //array all belong to the same group. The statuses that
            //`product.subscription.status` returns apply to the entire subscription group.
            guard let product = pricingManager.subscriptionProduct.value,
                  let statuses = try await product.subscription?.status else {
                return
            }

            var highestStatus: Product.SubscriptionInfo.Status? = nil
            var highestProduct: Product? = nil

            //Iterate through `statuses` for this subscription group and find
            //the `Status` with the highest level of service that isn't
            //in an expired or revoked state. For example, a customer may be subscribed to the
            //same product with different levels of service through Family Sharing.
            for status in statuses {
                switch status.state {
                case .expired, .revoked:
                    continue
                default:
                    let renewalInfo = try pricingManager.checkVerified(status.renewalInfo)

                    //Find the first subscription product that matches the subscription status renewal info by comparing the product IDs.
                    if renewalInfo.currentProductID == subscription?.id {
                        highestStatus = status
                        highestProduct = subscription
                    } else {
                        continue
                    }
                }
            }

            status = highestStatus
            purchasedSubscription = highestProduct
        } catch {
            print("Could not update subscription status \(error)")
        }
    }
}

