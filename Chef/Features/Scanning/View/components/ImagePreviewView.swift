import SwiftUI

struct ImagePreviewView: View {
    let image: UIImage
    @Binding var descriptionHint: String
    let onScan: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = false
    @State private var showCompletionAlert = false
    @State private var scanSummary = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("描述提示（選填）")
                        .font(.headline)
                    
                    TextField("例如：蔬菜和鍋子", text: $descriptionHint)
                        .textFieldStyle(.roundedBorder)
                        .padding(.bottom, 8)
                    
                    Text("描述圖片中的內容可以幫助系統更準確地識別食材和設備。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    isScanning = true
                    onScan()
                }) {
                    HStack {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text(isScanning ? "掃描中..." : "開始掃描")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isScanning)
            }
            .padding()
            .navigationTitle("圖片預覽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isScanning)
                }
            }
            .alert("掃描完成", isPresented: $showCompletionAlert) {
                Button("完成") {
                    dismiss()
                }
            } message: {
                Text(scanSummary)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 設置掃描完成狀態
    func setScanningComplete(summary: String) {
        isScanning = false
        scanSummary = summary
        showCompletionAlert = true
    }
}

// MARK: - Preview
#Preview {
    ImagePreviewView(
        image: UIImage(systemName: "photo")!,
        descriptionHint: .constant(""),
        onScan: {}
    )
} 