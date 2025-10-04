//
//  RecipeStepView.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import SwiftUI

struct RecipeStepView: View {
    let step: RecipeStep
    let stepIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step Header
            HStack {
                // Step Number
                Text("\(stepIndex)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.brandOrange)
                    .clipShape(Circle())

                // Step Title
                Text(step.title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Time and Temperature
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(step.estimated_total_time)
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "thermometer.sun")
                            .font(.caption)
                        Text(step.temperature)
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }

            // Step Description
            Text(step.description)
                .font(.body)
                .padding(.leading, 36)

            // Actions List
            if !step.actions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(step.actions, id: \.instruction_detail) { action in
                        ActionDetailView(action: action)
                    }
                }
                .padding(.leading, 36)
            }

            // Warnings (if any)
            if let warnings = step.warnings, !warnings.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text(warnings)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.leading, 36)
                .padding(.top, 4)
            }

            // Notes (if any)
            if !step.notes.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    Text(step.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 36)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Action Detail View

private struct ActionDetailView: View {
    let action: Action

    var body: some View {
        HStack(spacing: 8) {
            // Action Icon
            Image(systemName: iconForAction(action.action))
                .foregroundColor(.brandOrange)
                .frame(width: 16)

            // Action Detail
            VStack(alignment: .leading, spacing: 2) {
                Text(action.action)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if !action.instruction_detail.isEmpty {
                    Text(action.instruction_detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !action.material_required.isEmpty {
                    Text("需要: \(action.material_required.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    private func iconForAction(_ action: String) -> String {
        switch action.lowercased() {
        case "切", "切片", "切塊", "切丁":
            return "scissors"
        case "煎":
            return "circle.fill"
        case "炒":
            return "tornado"
        case "煮", "燉":
            return "drop.fill"
        case "蒸":
            return "cloud.fill"
        case "烤":
            return "flame.fill"
        case "炸":
            return "burst.fill"
        default:
            return "circle"
        }
    }

    private func formatActionTime(_ minutes: Int) -> String {
        // 小步驟通常都是短時間動作，應該以秒為單位顯示
        // 只有超過 3 分鐘的動作才顯示為分鐘
        if minutes == 0 {
            return "數秒"
        } else if minutes <= 3 {
            let seconds = minutes * 60
            return "\(seconds)秒"
        } else {
            return "\(minutes)分鐘"
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleAction = Action(
        action: "煎",
        tool_required: "平底鍋",
        material_required: ["蛋"],
        time_minutes: 3,
        instruction_detail: "蛋液均勻攤平"
    )

    let sampleStep = RecipeStep(
        step_number: 1,
        title: "煎蛋",
        description: "將蛋液倒入鍋中，小火煎熟。",
        actions: [sampleAction],
        estimated_total_time: "3分鐘",
        temperature: "小火",
        warnings: "注意不要燒焦",
        notes: "可加鹽調味"
    )

    RecipeStepView(step: sampleStep, stepIndex: 1)
        .padding()
}