import SwiftUI

// MARK: - SRT Converter View
struct SRTConverterView: View {
    @StateObject private var viewModel = SRTConverterViewModel()

    var body: some View {
        Group {
            if viewModel.conversionComplete {
                SRTConverterResultView(viewModel: viewModel)
            } else {
                SRTConverterInputView(viewModel: viewModel)
            }
        }
    }
}
