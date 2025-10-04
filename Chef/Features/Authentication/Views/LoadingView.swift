//
//  LoadingView.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/4/10.
//

import SwiftUI

struct LoadingView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    var body: some View {
        ZStack {
            Image("LoadingBg")
                .resizable()
                .scaleEffect(1.2)
            Image("QuickFeatLogo")
                .padding(.top, -350)
            Text("Loading...")
                .bold(true)
                .font(.system(size: 50, weight: .bold, design: .default))
                .foregroundColor(.white)
        }
        
   }
}

#Preview {
    LoadingView()
}
