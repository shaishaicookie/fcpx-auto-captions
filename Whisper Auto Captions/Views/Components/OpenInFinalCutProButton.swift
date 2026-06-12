import SwiftUI

struct OpenInFinalCutProButton: View {
    let fcpxmlPath: String
    var label: String = "Open in Final Cut Pro"
    var onFailure: ((String) -> Void)?

    var body: some View {
        Button(action: {
            FCPXMLService.openInFinalCutPro(fcpxmlPath: fcpxmlPath) { result in
                if case .failure(let error) = result {
                    onFailure?(error.localizedDescription)
                }
            }
        }) {
            fcpxIcon
            Text(label)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.gray)
    }

    @ViewBuilder
    private var fcpxIcon: some View {
        if let imagePath = Bundle.main.path(forResource: "fcpx-icon", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: imagePath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: nsImage.size.width * 0.05, height: nsImage.size.height * 0.05)
        }
    }
}
