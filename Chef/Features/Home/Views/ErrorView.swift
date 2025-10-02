//
//  ErrorView.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/12.
//
import SwiftUI

struct ErrorView: View {
    // MARK: - Properties
    let message: String
    let icon: String
    let iconColor: Color
    let onRetry: (() -> Void)?
    
    // MARK: - Initialization
    init(
        _ message: String,
        icon: String = "exclamationmark.triangle",
        iconColor: Color = .yellow,
        onRetry: (() -> Void)? = nil
    ) {
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.onRetry = onRetry
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
            
            Text(message)
                .multilineTextAlignment(.center)
            
            if let onRetry {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重試")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
    }
}

// MARK: - Preview
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ErrorView(Strings.somethingWentWrong)
            ErrorView(
                Strings.noInternet,
                icon: "wifi.slash",
                iconColor: .red
            )
            ErrorView(
                Strings.requestTimeout,
                onRetry: { print("重試被點擊") }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
