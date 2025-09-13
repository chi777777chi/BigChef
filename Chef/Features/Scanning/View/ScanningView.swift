import SwiftUI

// MARK: - Main View
struct ScanningView: View {
    @StateObject private var state: ScanningState
    @StateObject private var viewModel: ScanningViewModel
    @EnvironmentObject private var coordinator: ScanningCoordinator
    
    init(
        state: ScanningState,
        viewModel: ScanningViewModel,
        coordinator: ScanningCoordinator
    ) {
        self._state = StateObject(wrappedValue: state)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    logoView
                    equipmentSection
                    ingredientSection
                    preferenceSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("食譜生成器")
            .navigationBarTitleDisplayMode(.large)
            .modifier(SheetModifier(state: state, viewModel: viewModel))
            .modifier(AlertModifier(state: state))
            .modifier(LoadingModifier(isLoading: viewModel.isLoading))
            .modifier(ImagePickerModifier(viewModel: viewModel))
        }
    }
    
    // MARK: - View Components
    
    private var logoView: some View {
        LogoView()
    }
    
    private var equipmentSection: some View {
        EquipmentSectionView(
            equipment: viewModel.equipment,
            onAdd: { state.showSheet(.equipment(Equipment.empty)) },
            onEdit: { equipment in state.showSheet(.equipment(equipment)) },
            onDelete: { equipment in
                withAnimation(.easeInOut) {
                    viewModel.removeEquipment(equipment)
                }
            }
        )
    }
    
    private var ingredientSection: some View {
        IngredientSectionView(
            ingredients: viewModel.ingredients,
            onAdd: { state.showSheet(.ingredient(Ingredient.empty)) },
            onEdit: { ingredient in state.showSheet(.ingredient(ingredient)) },
            onDelete: { ingredient in
                withAnimation(.easeInOut) {
                    viewModel.removeIngredient(ingredient)
                }
            }
        )
    }
    
    private var preferenceSection: some View {
        PreferenceSectionView(viewModel: viewModel)
    }
    
    private var actionButtons: some View {
        ActionButtonsView(
            onScan: { viewModel.showImagePicker() },
            onGenerate: {
                Task {
                    await viewModel.generateRecipe()
                }
            }
        )
    }
}

// MARK: - View Modifiers

private struct SheetModifier: ViewModifier {
    @ObservedObject var state: ScanningState
    @ObservedObject var viewModel: ScanningViewModel
    
    func body(content: Content) -> some View {
        content
            .sheet(item: Binding(
                get: { state.activeSheet },
                set: { state.activeSheet = $0 }
            )) { sheet in
                sheetContent(for: sheet)
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isShowingImagePreview },
                set: { _ in viewModel.hideImagePreview() }
            )) {
                if let image = viewModel.selectedImage {
                    ImagePreviewView(
                        image: image,
                        descriptionHint: Binding(
                            get: { viewModel.descriptionHint },
                            set: { viewModel.updateDescriptionHint($0) }
                        ),
                        onScan: {
                            Task {
                                await viewModel.scanImage()
                            }
                        }
                    )
                }
            }
    }
    
    
    @ViewBuilder
    private func sheetContent(for sheet: ScanningSheet) -> some View {
        switch sheet {
        case .ingredient(let ingredient):
            IngredientEditView(
                ingredient: ingredient,
                onSave: { newIngredient in
                    viewModel.upsertIngredient(newIngredient)
                    state.dismissSheet()
                },
                onCancel: state.dismissSheet
            )
            
        case .equipment(let equipment):
            EquipmentEditView(
                equipment: equipment,
                onSave: { newEquipment in
                    viewModel.upsertEquipment(newEquipment)
                    state.dismissSheet()
                },
                onCancel: state.dismissSheet
            )
        }
    }
}

private struct AlertModifier: ViewModifier {
    @ObservedObject var state: ScanningState
    
    func body(content: Content) -> some View {
        content
            .alert("掃描完成", isPresented: Binding(
                get: { state.showCompletionAlert },
                set: { if !$0 { state.reset() } }
            )) {
                Button("完成", role: .cancel) {
                    state.reset()
                }
            } message: {
                Text(state.scanSummary)
            }
    }
}

private struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
    }
}

private struct ImagePickerModifier: ViewModifier {
    @ObservedObject var viewModel: ScanningViewModel
    
    func body(content: Content) -> some View {
        content
            .imageSourcePicker(
                isPresented: Binding(
                    get: { viewModel.isShowingImagePicker },
                    set: { if !$0 { viewModel.hideImagePicker() } }
                ),
                selectedImage: Binding(
                    get: { viewModel.selectedImage },
                    set: { viewModel.handleSelectedImage($0) }
                ),
                onImageSelected: { image in
                    viewModel.handleSelectedImage(image)
                }
            )
    }
}

// MARK: - Preview
struct ScanningView_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        let state = ScanningState()
        let viewModel = ScanningViewModel(
            state: state,
            onNavigateToRecipe: { _ in }
        )
        let coordinator = ScanningCoordinator(navigationController: UINavigationController())
        
        return ScanningView(
            state: state,
            viewModel: viewModel,
            coordinator: coordinator
        )
        .environmentObject(coordinator)
    }
}

