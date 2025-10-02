import SwiftUI

struct PreferenceSectionView: View {
    @ObservedObject var viewModel: ScanningViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("烹調偏好")
                .font(.headline)
            
            PreferenceView(
                cookingMethod: Binding(
                    get: { viewModel.cookingMethod },
                    set: { viewModel.updateCookingMethod($0) }
                ),
                dietaryRestrictionsInput: Binding(
                    get: { viewModel.dietaryRestrictionsString },
                    set: { viewModel.updateDietaryRestrictions($0) }
                ),
                servingSize: Binding(
                    get: { viewModel.servingSize },
                    set: { viewModel.updateServingSize($0) }
                )
            )
        }
    }
} 