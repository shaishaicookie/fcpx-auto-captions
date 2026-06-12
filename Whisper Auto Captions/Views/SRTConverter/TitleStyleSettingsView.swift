import SwiftUI

// MARK: - Title Style Settings View (Popup)
struct TitleStyleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SRTConverterViewModel
    let availableFonts: [String]

    // 로컬 편집용 상태 (View 업데이트 중 publishing 방지)
    @State private var localTitleStyle: TitleStyleSettings

    private let labelWidth: CGFloat = 70

    init(viewModel: SRTConverterViewModel, availableFonts: [String]) {
        self.viewModel = viewModel
        self.availableFonts = availableFonts
        // 초기값으로 ViewModel의 현재 값 복사
        _localTitleStyle = State(initialValue: viewModel.titleStyle)
    }

    // MARK: - Position Preset Binding (delegates to ViewModel)
    private var positionPresetBinding: Binding<PositionPreset> {
        Binding(
            get: { localTitleStyle.positionPreset },
            set: { newPreset in
                localTitleStyle.positionPreset = newPreset
                // Position 값 업데이트 (ViewModel의 로직 활용)
                let (x, y) = viewModel.calculatePositionForPreset(newPreset)
                localTitleStyle.positionX = x
                localTitleStyle.positionY = y
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(String(localized: "Title Style", comment: "Title style popup header"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()

            Divider()

            // Content
            HStack(alignment: .top, spacing: 0) {
                TitleStylePreviewView(
                    width: previewWidth,
                    height: previewHeight,
                    titleStyle: $localTitleStyle
                )
                .padding()
                .frame(width: 300, alignment: .top)
                .frame(maxHeight: .infinity, alignment: .top)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        positionSection
                        Divider()
                        fontSection
                        Divider()
                        colorSection
                        Divider()
                        alignmentSection
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer
            HStack {
                Spacer()
                Button(String(localized: "Done", comment: "Done button")) {
                    saveAndDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 760, height: 540)
    }

    private var previewWidth: Int {
        viewModel.isResolutionValid ? viewModel.currentWidth : VideoResolution.fullHD1080p.width
    }

    private var previewHeight: Int {
        viewModel.isResolutionValid ? viewModel.currentHeight : VideoResolution.fullHD1080p.height
    }

    // MARK: - Position Section
    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Position", comment: "Position label"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text(String(localized: "Preset:", comment: "Position preset label"))
                        .frame(width: labelWidth, alignment: .trailing)
                    Picker(selection: positionPresetBinding, label: EmptyView()) {
                        ForEach(PositionPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 200)
                }

                if localTitleStyle.positionPreset == .custom {
                    GridRow {
                        Text(String(localized: "Offset:", comment: "Position offset label"))
                            .frame(width: labelWidth, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 8) {
                            coordinateControl(
                                label: "X",
                                value: $localTitleStyle.positionX,
                                range: horizontalPositionRange
                            )
                            coordinateControl(
                                label: "Y",
                                value: $localTitleStyle.positionY,
                                range: verticalPositionRange
                            )
                        }
                    }
                }
            }
        }
    }

    private var horizontalPositionRange: ClosedRange<CGFloat> {
        let halfWidth = CGFloat(max(previewWidth, 1)) / 2
        return -halfWidth...halfWidth
    }

    private var verticalPositionRange: ClosedRange<CGFloat> {
        let coordinateSize = TitlePreviewGeometry.positionCoordinateSize(
            videoWidth: previewWidth,
            videoHeight: previewHeight
        )
        let halfHeight = coordinateSize.height / 2
        return -halfHeight...halfHeight
    }

    private func coordinateControl(
        label: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>
    ) -> some View {
        HStack(spacing: 8) {
            Text(verbatim: "\(label):")
                .frame(width: 20, alignment: .trailing)
            Slider(value: value, in: range, step: 1)
                .frame(width: 220)
            TextField("0", value: value, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 70)
        }
    }

    // MARK: - Font Section
    private var fontSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Font", comment: "Font label"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                // Font Family
                GridRow {
                    Text(String(localized: "Family:", comment: "Font family label"))
                        .frame(width: labelWidth, alignment: .trailing)
                    Picker(selection: $localTitleStyle.fontName, label: EmptyView()) {
                        ForEach(availableFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 220)
                }

                // Font Size
                GridRow {
                    Text(String(localized: "Size:", comment: "Font size label"))
                        .frame(width: labelWidth, alignment: .trailing)
                    HStack(spacing: 8) {
                        Slider(value: $localTitleStyle.fontSize, in: CGFloat(10)...CGFloat(200), step: 1)
                            .frame(width: 220)
                        TextField("45", value: $localTitleStyle.fontSize, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                        Text("pt")
                    }
                }

                // Font Scale
                GridRow {
                    Text(String(localized: "Scale:", comment: "Font scale mode label"))
                        .frame(width: labelWidth, alignment: .trailing)
                    Picker(selection: $localTitleStyle.fontScaleMode, label: EmptyView()) {
                        ForEach(TitleFontScaleMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 240)
                }

                // Font Weight
                GridRow {
                    Text(String(localized: "Weight:", comment: "Font weight label"))
                        .frame(width: labelWidth, alignment: .trailing)
                    Picker(selection: $localTitleStyle.fontWeight, label: EmptyView()) {
                        ForEach(TitleFontWeight.allCases) { weight in
                            Text(weight.displayName).tag(weight)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 120)
                }
            }
        }
    }

    // MARK: - Color Section
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Colors", comment: "Colors label"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                // Text Color
                GridRow {
                    Text(String(localized: "Text:", comment: "Text color label"))
                        .frame(width: labelWidth, alignment: .trailing)
                    ColorPicker("", selection: textColorBinding)
                        .labelsHidden()
                }

                // Stroke
                GridRow {
                    Text(String(localized: "Stroke:", comment: "Stroke label"))
                        .frame(width: labelWidth, alignment: .trailing)
                    HStack(spacing: 8) {
                        Toggle("", isOn: $localTitleStyle.strokeEnabled)
                            .labelsHidden()
                            .toggleStyle(.checkbox)
                        if localTitleStyle.strokeEnabled {
                            ColorPicker("", selection: strokeColorBinding)
                                .labelsHidden()
                            HStack(spacing: 4) {
                                TextField("2", value: $localTitleStyle.strokeWidth, formatter: NumberFormatter())
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 40)
                                Text("pt")
                            }
                        }
                    }
                }

                // Shadow
                GridRow {
                    Text(String(localized: "Shadow:", comment: "Shadow label"))
                        .frame(width: labelWidth, alignment: .trailing)
                    HStack(spacing: 8) {
                        ColorPicker("", selection: shadowColorBinding)
                            .labelsHidden()
                        HStack(spacing: 4) {
                            Text("X:")
                            TextField("4", value: $localTitleStyle.shadowOffsetX, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 40)
                        }
                        HStack(spacing: 4) {
                            Text("Y:")
                            TextField("315", value: $localTitleStyle.shadowOffsetY, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 40)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Alignment Section
    private var alignmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Alignment", comment: "Alignment label"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker(selection: $localTitleStyle.alignment, label: EmptyView()) {
                ForEach(TitleTextAlignment.allCases) { alignment in
                    Text(alignment.displayName).tag(alignment)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 200)
        }
    }

    // MARK: - Color Bindings

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { localTitleStyle.textColor.color },
            set: { localTitleStyle.textColor = CodableColor(color: NSColor($0)) }
        )
    }

    private var strokeColorBinding: Binding<Color> {
        Binding(
            get: { localTitleStyle.strokeColor.color },
            set: { localTitleStyle.strokeColor = CodableColor(color: NSColor($0)) }
        )
    }

    private var shadowColorBinding: Binding<Color> {
        Binding(
            get: { localTitleStyle.shadowColor.color },
            set: { localTitleStyle.shadowColor = CodableColor(color: NSColor($0)) }
        )
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        viewModel.titleStyle = localTitleStyle
        dismiss()
    }
}

// MARK: - Title Style Preview
private struct TitleStylePreviewView: View {
    let width: Int
    let height: Int
    @Binding var titleStyle: TitleStyleSettings

    private var resolvedStyle: TitleStyleSettings {
        titleStyle.resolved(forWidth: width, height: height)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "Preview", comment: "Title style preview label"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(verbatim: "\(width)×\(height)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { proxy in
                let canvasSize = TitlePreviewGeometry.fittedCanvasSize(
                    videoWidth: width,
                    videoHeight: height,
                    in: proxy.size
                )
                let previewGeometry = TitlePreviewGeometry(
                    videoWidth: width,
                    videoHeight: height,
                    canvasSize: canvasSize
                )
                let scale = previewGeometry.scale
                let textFrameWidth = captionFrameWidth(canvasSize: canvasSize)

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.07, green: 0.08, blue: 0.09))

                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        .padding(16)

                    captionText(scale: scale)
                        .frame(
                            width: textFrameWidth,
                            alignment: textFrameAlignment
                        )
                        .position(captionDisplayPosition(in: previewGeometry, frameWidth: textFrameWidth))
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updatePosition(from: value.location, in: previewGeometry)
                        }
                )
            }
            .frame(height: 260)
        }
    }

    private func captionFrameWidth(canvasSize: CGSize) -> CGFloat {
        min(max(80, canvasSize.width * 0.72), canvasSize.width)
    }

    private func captionAnchorPoint(in geometry: TitlePreviewGeometry) -> CGPoint {
        geometry.clampedPreviewPoint(
            forFCPXMLPosition: CGPoint(
                x: resolvedStyle.positionX,
                y: resolvedStyle.positionY
            )
        )
    }

    private func captionDisplayPosition(in geometry: TitlePreviewGeometry, frameWidth: CGFloat) -> CGPoint {
        let anchorPoint = captionAnchorPoint(in: geometry)
        let xOffset: CGFloat

        switch resolvedStyle.alignment {
        case .left:
            xOffset = frameWidth / 2
        case .center:
            xOffset = 0
        case .right:
            xOffset = -frameWidth / 2
        }

        return CGPoint(x: anchorPoint.x + xOffset, y: anchorPoint.y)
    }

    private func updatePosition(from location: CGPoint, in geometry: TitlePreviewGeometry) {
        guard geometry.scale > 0 else { return }

        let nextPosition = geometry.clampedFCPXMLPosition(forPreviewPoint: location)
        titleStyle.positionPreset = .custom
        titleStyle.positionX = nextPosition.x
        titleStyle.positionY = nextPosition.y
    }

    private func captionText(scale: CGFloat) -> some View {
        let fontSize = max(8, resolvedStyle.fontSize * scale)
        let strokeRadius = resolvedStyle.strokeEnabled
            ? max(0.5, resolvedStyle.strokeWidth * scale * 0.8)
            : 0
        let shadowX = resolvedStyle.shadowOffsetX * scale
        let shadowY = -resolvedStyle.shadowOffsetY * scale * 0.12

        return Text(String(localized: "Sample Caption\nPosition Preview", comment: "Title style preview sample text"))
            .font(.custom(resolvedStyle.fontName, size: fontSize))
            .fontWeight(swiftUIFontWeight)
            .foregroundColor(resolvedStyle.textColor.color)
            .multilineTextAlignment(textAlignment)
            .shadow(
                color: resolvedStyle.strokeEnabled ? resolvedStyle.strokeColor.color : .clear,
                radius: strokeRadius,
                x: 0,
                y: 0
            )
            .shadow(
                color: resolvedStyle.shadowColor.color,
                radius: 2,
                x: shadowX,
                y: shadowY
            )
    }

    private var textAlignment: TextAlignment {
        switch resolvedStyle.alignment {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    private var textFrameAlignment: Alignment {
        switch resolvedStyle.alignment {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    private var swiftUIFontWeight: Font.Weight {
        switch resolvedStyle.fontWeight {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}
