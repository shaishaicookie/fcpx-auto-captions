//
//  SettingRow.swift
//  Whisper Auto Captions
//
//  Reusable setting row component with label and info button
//

import SwiftUI

struct SettingRow<Content: View>: View {
    let label: LocalizedStringKey
    let infoTitle: LocalizedStringKey
    let infoDescription: LocalizedStringKey
    var infoRecommendation: LocalizedStringKey? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 150, alignment: .trailing)
            content()
            Spacer()
            InfoButton(
                title: infoTitle,
                description: infoDescription,
                recommendation: infoRecommendation
            )
        }
    }
}
