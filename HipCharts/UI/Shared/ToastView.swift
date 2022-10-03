//
//  ToastView.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/18/22.
//

import Foundation
import SwiftUI

struct Toast: ViewModifier {
    static let short: TimeInterval = 2
    static let long: TimeInterval = 3.5
    
    @Binding var message: String?
    let config: Config
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if let message = message {
                toastView(message: message)
            }
        }
    }
    
    private func toastView(message: String) -> some View {
        VStack {
            if let message = message {
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(config.textColor)
                    .font(config.font)
                    .padding()
                    .cornerRadius(8)
                    .onTapGesture {
                        self.message = nil
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
                            self.message = nil
                        }
                    }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8).stroke(config.borderColor)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(config.backgroundColor)
                )
        )
        .transition(config.transition)
    }
    
    struct Config {
        let textColor: Color
        let font: Font
        let backgroundColor: Color
        let borderColor: Color
        let duration: TimeInterval
        let transition: AnyTransition
        let animation: Animation
        
        init(textColor: Color = .label,
             font: Font = .body,
             backgroundColor: Color = .systemBackground.opacity(0.9),
             borderColor: Color = .systemBackground,
             duration: TimeInterval = Toast.short,
             transition: AnyTransition = .move(edge: .top),
             animation: Animation = .linear(duration: 0.3)) {
            self.textColor = textColor
            self.font = font
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.duration = duration
            self.transition = transition
            self.animation = animation
        }
    }
}

extension View {
    func toast(message: Binding<String?>,
               config: Toast.Config) -> some View {
        self.modifier(Toast(message: message,
                            config: config))
    }
    
    func toast(message: Binding<String?>,
               duration: TimeInterval = Toast.long) -> some View {
        self.modifier(Toast(message: message,
                            config: .init(duration: duration)))
    }
}
