import SwiftUI

// MARK: - Transcription Tab
struct TranscriptionTab: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        Group {
            if viewModel.startCreatingAutoCaptions {
                ProcessView(viewModel: viewModel)
            } else {
                HomeView(viewModel: viewModel)
            }
        }
    }
}
