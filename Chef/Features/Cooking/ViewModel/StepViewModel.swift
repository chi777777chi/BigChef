//
//  StepViewModel.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/17.
//

import Foundation
import Combine

class StepViewModel: ObservableObject {
    @Published var currentDescription: String = "" {
        didSet {
            print("📝 [StepViewModel] currentDescription changed")
        }
    }
    @Published var currentStepModel: RecipeStep? {
        didSet {
            print("📝 [StepViewModel] currentStepModel changed: \(oldValue?.step_number ?? -1) -> \(currentStepModel?.step_number ?? -1)")
        }
    }
}
