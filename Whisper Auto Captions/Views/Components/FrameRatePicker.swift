import SwiftUI

struct FrameRatePicker: View {
    @Binding var selectedFrameRate: FrameRate
    @Binding var customFps: String
    let isFpsValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(selection: $selectedFrameRate, label: EmptyView()) {
                ForEach(FrameRate.allCases) { frameRate in
                    Text(frameRate.displayName).tag(frameRate)
                }
            }
            .pickerStyle(MenuPickerStyle())

            if selectedFrameRate == .custom {
                HStack(spacing: 8) {
                    TextField("fps", text: $customFps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 70)
                    Text("fps")
                }

                if !isFpsValid {
                    Text(String(localized: "Frame rate must be between 0 and 120", comment: "Invalid frame rate error"))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .frame(maxWidth: 300, alignment: .leading)
    }
}
