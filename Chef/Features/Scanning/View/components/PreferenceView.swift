import SwiftUI

struct PreferenceView: View {
    @Binding var cookingMethod: String
    @Binding var dietaryRestrictionsInput: String
    @Binding var servingSize: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("偏好設定").font(.title2).bold()

            VStack(alignment: .leading, spacing: 4) {
                Text("製作方式（選填）")
                    .font(.headline)
                TextField("例如：煎、炒、煮...", text: $cookingMethod)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("飲食限制（選填）")
                    .font(.headline)
                TextField("例如：無麩質、素食...", text: $dietaryRestrictionsInput)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)
            }

            HStack {
                Text("份量").font(.headline)
                Spacer()
                Picker("份量", selection: $servingSize) {
                    ForEach(1..<11) { size in
                        Text("\(size)人份").tag(size)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 80)
            }
        }
    }
}
