//
//  RecipeLoadingView.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/4.
//

import SwiftUI

struct RecipeLoadingView: View {
    var message: String = "正在生成食譜中..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text(message)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
        }
    }
}

#Preview {
    RecipeLoadingView()
}
