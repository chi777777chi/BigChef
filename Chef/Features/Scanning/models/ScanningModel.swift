import SwiftUI

// MARK: - Model Extensions
extension Ingredient {
    static var empty: Self {
        Ingredient(name: "", type: "", amount: "", unit: "", preparation: "")
    }
}

extension Equipment {
    static var empty: Self {
        Equipment(name: "", type: "", size: "", material: "", power_source: "")
    }
}
