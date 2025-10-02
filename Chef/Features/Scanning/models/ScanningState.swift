import Foundation
import SwiftUI

/// 集中管理 Scanning 功能的所有狀態
@MainActor
final class ScanningState: ObservableObject {
    // MARK: - UI States
    @Published var activeSheet: ScanningSheet?
    @Published var showCompletionAlert = false
    @Published var scanSummary = ""
    
    // MARK: - Data States
    @Published var preference: Preference = Preference(
        cooking_method: "一般烹調",
        dietary_restrictions: [],
        serving_size: "1人份"
    )
    
    // MARK: - Computed Properties
    
    var hasActiveSheet: Bool {
        activeSheet != nil
    }
    
    // MARK: - Methods
    
    func showSheet(_ sheet: ScanningSheet) {
        activeSheet = sheet
    }
    
    func dismissSheet() {
        activeSheet = nil
    }
    
    func showCompletionAlert(with summary: String) {
        scanSummary = summary
        showCompletionAlert = true
    }
    
    func reset() {
        activeSheet = nil
        showCompletionAlert = false
        scanSummary = ""
        preference = Preference(
            cooking_method: "一般烹調",
            dietary_restrictions: [],
            serving_size: "1人份"
        )
    }
}

// MARK: - Sheet Types
enum ScanningSheet: Identifiable {
    case ingredient(Ingredient)
    case equipment(Equipment)
    
    var id: String {
        switch self {
        case .ingredient(let item): return "ingredient-\(item.id)"
        case .equipment(let item): return "equipment-\(item.id)"
        }
    }
} 