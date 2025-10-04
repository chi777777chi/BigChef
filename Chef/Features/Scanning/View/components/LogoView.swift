import SwiftUI

struct LogoView: View {
    var body: some View {
        HStack {
            Spacer()
            Image("QuickFeatLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
        }
    }
} 