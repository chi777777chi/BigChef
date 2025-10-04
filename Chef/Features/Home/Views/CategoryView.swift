//
//  CategoryView.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/12.
//

import SwiftUI

struct CategoryView: View {
    // MARK: - Properties
    let dish: DishCategory
    let onTap: (() -> Void)?
    
    // MARK: - Initialization
    init(dish: DishCategory, onTap: (() -> Void)? = nil) {
        self.dish = dish
        self.onTap = onTap
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .center, spacing: 16) {
                CachedAsyncImage(
                    url: URL(string: dish.image),
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    },
                    placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    }
                )
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                Text(dish.name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 128, height: 128)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct CategoryView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                CategoryView(dish: DishCategory.preview)
                CategoryView(
                    dish: DishCategory(
                        id: "2",
                        name: "測試分類2",
                        image: "https://picsum.photos/201"
                    ),
                    onTap: { print("分類被點擊") }
                )
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
