import SwiftUI
import PhotosUI

struct ImageSourcePicker: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("選擇圖片來源", isPresented: $isPresented) {
                Button("拍照") {
                    showImagePicker(sourceType: .camera)
                }
                Button("相簿") {
                    showImagePicker(sourceType: .photoLibrary)
                }
                Button("取消", role: .cancel) {}
            }
            .sheet(isPresented: $isShowingImagePicker) {
                if let sourceType = currentSourceType {
                    ImagePicker(
                        sourceType: sourceType,
                        selectedImage: $selectedImage,
                        onImageSelected: onImageSelected
                    )
                }
            }
    }
    
    @State private var isShowingImagePicker = false
    @State private var currentSourceType: UIImagePickerController.SourceType?
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        currentSourceType = sourceType
        isShowingImagePicker = true
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

extension View {
    func imageSourcePicker(
        isPresented: Binding<Bool>,
        selectedImage: Binding<UIImage?>,
        onImageSelected: @escaping (UIImage) -> Void
    ) -> some View {
        modifier(ImageSourcePicker(
            isPresented: isPresented,
            selectedImage: selectedImage,
            onImageSelected: onImageSelected
        ))
    }
} 