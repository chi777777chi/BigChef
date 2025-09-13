//
//  RecipeView.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/4.
//
import SwiftUI

struct RecipeView: View {
    @ObservedObject var viewModel: RecipeViewModel

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 16) {
                    // 頂部圖片
                    Image(systemName: "leaf")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .padding(.top, 20)

                    Text("食譜")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Text(viewModel.dishName)
                        .font(.title)
                        .bold()

                    Text(viewModel.dishDescription)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text("食材")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("烹飪步驟")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let maxTextWidth = UIScreen.main.bounds.width * 0.8

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.steps.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("步驟 \(viewModel.steps[index].step_number)：\(viewModel.steps[index].title)")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text(viewModel.steps[index].description)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .frame(width: maxTextWidth, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }

            // 按鈕區拉出來，不跟著 ScrollView 滾動
            Button(action: {
                viewModel.cookButtonTapped()
                // 將跳轉 CameraCookingView 的邏輯放這裡
            }) {
                Text("開始烹飪")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brandOrange)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}

#Preview {
    let sampleAction = Action(
        action: "煎",
        tool_required: "平底鍋",
        material_required: ["牛排"],
        time_minutes: 5,
        instruction_detail: "煎至表面微焦並鎖住肉汁"
    )

    let sampleStep = RecipeStep(
        step_number: 1,
        title: "煎牛排",
        description: "將牛排從冰箱取出，放置於室溫約 20 分鐘，讓其回溫。",
        actions: [sampleAction],
        estimated_total_time: "5分鐘",
        temperature: "中火",
        warnings: nil,
        notes: "可加海鹽與胡椒調味"
    )

    let sampleIngredient = Ingredient(
        name: "牛排",
        type: "肉類",
        amount: "1",
        unit: "塊",
        preparation: "室溫退冰"
    )

    let sampleEquipment = Equipment(
        name: "平底鍋",
        type: "鍋具",
        size: "中型",
        material: "鐵",
        power_source: "瓦斯"
    )

    let response = SuggestRecipeResponse(
        dish_name: "健康沙拉",
        dish_description: "一道清爽健康的料理",
        ingredients: [sampleIngredient],
        equipment: [sampleEquipment],
        recipe: [sampleStep, sampleStep]
    )

    let viewModel = RecipeViewModel(response: response)
    return RecipeView(viewModel: viewModel)
}
