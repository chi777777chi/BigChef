import SwiftUI

struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    if let message = message {
                        Text(message)
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .padding(24)
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
} 