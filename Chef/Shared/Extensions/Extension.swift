//
//  Extension.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/4/9.
//
import UIKit
import SwiftUI
extension View{
    func scanningButtonStyle() -> some View{
        padding()
        .background(Color.brandOrange)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
    func ViewStyle()-> some View{
        font(.title)
        .foregroundColor(.brandOrange)
        .bold()
        .padding(.horizontal, 20)
        .ignoresSafeArea(edges: .bottom)
        .offset(y:25)
    }
}

extension Color {
    static let brandOrange = Color(red: 178/255, green: 72/255, blue: 22/255)
}



extension UIColor {
    static let brandOrange = UIColor(red: 178/255, green: 72/255, blue: 22/255, alpha: 1)
}





struct GeneratedReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    
    let generatedDishName: String
    let generatedDishDescription: String
    let generatedSteps: [RecipeStep]
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header section
            VStack(alignment: .leading, spacing: 8) {
                Text("🍽️ \(generatedDishName)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(generatedDishDescription)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
                
                Divider()
            }
            
            // Steps section
            Text("食譜步驟")
                .font(.headline)
                .padding(.top, 4)
            
            if generatedSteps.isEmpty {
                Text("無可用的烹飪步驟")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(generatedSteps) { step in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("步驟 \(step.step_number): \(step.title)")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // Time and temperature info
                            if !step.estimated_total_time.isEmpty {
                                Label(step.estimated_total_time, systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            if !step.temperature.isEmpty {
                                Label(step.temperature, systemImage: "thermometer")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                contentView
            }
            .navigationTitle("食譜詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("分享") {
                        // Share functionality would go here
                    }
                    .disabled(generatedSteps.isEmpty)
                }
            }
            .onAppear {
                print("Sheet appeared with \(generatedSteps.count) steps")
                if !generatedSteps.isEmpty {
                    print("First step: \(generatedSteps[0].step_number)")
                }
            }
        }
    }
}
