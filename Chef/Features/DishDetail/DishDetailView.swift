//
//  DishDetailView.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/12.
//

import SwiftUI

struct DishDetailView: View {

    let recipe: Recipe

    @State private var isDescriptionExpanded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Main Content Card
                VStack(spacing: 20) {
                    // Title and Author Section
                    titleSection

                    // Image and Info Section
                    imageAndInfoSection

                    // Description Section
                    descriptionSection

                    // Additional Info Section
                    additionalInfoSection
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.1), radius: 8, x: 0, y: 2)
                .padding(.horizontal)

                // Bottom Action Section
                bottomActionSection
            }
        }
        .background(Color.gray.opacity(0.05))

        .navigationTitle(recipe.displayName)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {

                } label: {
                    Image(systemName: "heart")
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // MARK: - View Components

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                Text(recipe.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                if let rating = recipe.rating, rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.subheadline)
                        Text(String(format: "%.1f", rating))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }

            if let authorName = recipe.authorName, !authorName.isEmpty {
                Text("作者：\(authorName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("作者：未知")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var imageAndInfoSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // Info Tags (Vertical Layout)
            VStack(alignment: .leading, spacing: 12) {
                if let rating = recipe.rating, rating > 0 {
                    InfoTagView(
                        icon: "star.fill",
                        label: "評分",
                        value: String(format: "%.1f", rating),
                        color: .yellow
                    )
                }

                if !recipe.displayTotalTime.isEmpty && recipe.displayTotalTime != "未知" {
                    InfoTagView(
                        icon: "clock",
                        label: "總時間",
                        value: recipe.displayTotalTime,
                        color: .blue
                    )
                }

                // 新API沒有準備時間字段，暫時隱藏
                // if !recipe.displayPrepTime.isEmpty && recipe.displayPrepTime != "未知" {
                //     InfoTagView(
                //         icon: "timer",
                //         label: "準備",
                //         value: recipe.displayPrepTime,
                //         color: .green
                //     )
                // }

                if !recipe.displayCookTime.isEmpty && recipe.displayCookTime != "未知" {
                    InfoTagView(
                        icon: "flame",
                        label: "烹飪",
                        value: recipe.displayCookTime,
                        color: .orange
                    )
                }

                // 新API沒有份量字段，暫時隱藏
                // if !recipe.displayYield.isEmpty && recipe.displayYield != "未知份量" {
                //     InfoTagView(
                //         icon: "person.2",
                //         label: "份量",
                //         value: recipe.displayYield,
                //         color: .purple
                //     )
                // }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Recipe Image (Optimized)
            AsyncImage(url: URL(string: recipe.displayImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("載入中...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
            .frame(width: 180, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("描述")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.displayDescription)
                    .lineLimit(isDescriptionExpanded ? nil : 4)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: isDescriptionExpanded)

                // 新API沒有備註字段
                // if let notes = recipe.notes, !notes.isEmpty {
                //     Text("備註：\(notes)")
                //         .font(.caption)
                //         .foregroundColor(.secondary)
                //         .padding(.top, 4)
                // }

                Button {
                    withAnimation {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    Text(isDescriptionExpanded ? "收起" : "閱讀更多")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細資訊")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                if let createdAt = recipe.createdAt {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .frame(width: 20)

                        Text("發布日期")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formatDate(createdAt))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }

                // 新API中所有食譜都是已審核的，顯示默認狀態
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .frame(width: 20)

                    Text("狀態")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("已審核")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            // Price Section
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("價格")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("$137.50")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "book")
                            Text("查看食譜")
                        }
                        .font(.headline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text("加入購物車")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
    }

    // Helper function to format date
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.locale = Locale(identifier: "zh_TW")
            return displayFormatter.string(from: date)
        }

        // Try alternative format without milliseconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.locale = Locale(identifier: "zh_TW")
            return displayFormatter.string(from: date)
        }

        return dateString
    }
}

struct DishDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DishDetailView(recipe: Recipe.preview)
    }
}

struct RatingView: View {
    let imageName: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: imageName)                .foregroundColor(.pink)

            Text(text)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .overlay( /// apply a rounded border
            RoundedRectangle(cornerRadius: 20)
                .stroke(.gray, lineWidth: 1)
        )
    }
}

struct RideView: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("🚙")

            Text("20 min")
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .overlay( /// apply a rounded border
            RoundedRectangle(cornerRadius: 20)
                .stroke(.gray, lineWidth: 1)
        )
    }
}

struct InfoTagView: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TimeInfoView: View {
    let icon: String
    let label: String
    let time: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.pink)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(time)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
