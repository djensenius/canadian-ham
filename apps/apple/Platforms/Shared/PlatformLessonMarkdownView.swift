import CanadianHamContent
import CanadianHamEngine
import SwiftUI

struct LessonMarkdownView: View {
    let markdown: String
    let title: String?
    let targetAnchor: String?

    @AccessibilityFocusState private var focusedHeadingAnchor: String?
#if os(tvOS)
    @FocusState private var focusedBlockID: Int?
#endif

    init(markdown: String, title: String? = nil, targetAnchor: String? = nil) {
        self.markdown = markdown
        self.title = title
        self.targetAnchor = targetAnchor
    }

    init(lesson: Lesson, targetAnchor: String? = nil) {
        self.markdown = lesson.bodyMarkdown
        self.title = lesson.title.en
        self.targetAnchor = targetAnchor
    }

    var body: some View {
        let rendered = renderedMarkdown()
        let blocks = displayBlocks(rendered)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(blocks) { displayBlock in
                displayBlockView(displayBlock)
            }
        }
        .id(markdown)
        .onAppear { focusTargetHeadingAfterLayout() }
        .onChange(of: targetAnchor) { _, _ in focusTargetHeadingAfterLayout() }
    }

    @ViewBuilder
    private func displayBlockView(_ displayBlock: DisplayLessonBlock) -> some View {
#if os(tvOS)
        if case .tryIt = displayBlock.block {
            blockView(displayBlock.block, headingAnchor: displayBlock.headingAnchor, fallbackID: displayBlock.fallbackID)
                .padding(DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        } else {
            Group {
                blockView(displayBlock.block, headingAnchor: displayBlock.headingAnchor, fallbackID: displayBlock.fallbackID)
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .tvFocusRing(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous),
                isFocused: focusedBlockID == displayBlock.id,
                unfocusedColor: DesignTokens.Colors.border,
                unfocusedLineWidth: 1
            )
            .accessibilityElement(children: .combine)
            .focusable(true)
            .focused($focusedBlockID, equals: displayBlock.id)
            .focusEffectDisabled()
        }
#else
        blockView(displayBlock.block, headingAnchor: displayBlock.headingAnchor, fallbackID: displayBlock.fallbackID)
#endif
    }

    @ViewBuilder
    private func blockView(_ block: LessonBlock, headingAnchor: String?, fallbackID: String) -> some View {
        switch block {
        case .heading(let level, let text):
            if !(level == 1 && title != nil && plainString(text) == title) {
                headingView(level: level, text: text, headingAnchor: headingAnchor, fallbackID: fallbackID)
            }
        case .paragraph(let text):
            Text(lessonEnglish(strippingLinks(from: text))) // l10n: content(en)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
#if os(iOS) || os(macOS)
                .textSelection(.enabled)
#else
                .fixedSize(horizontal: false, vertical: true)
#endif
        case .tryIt(let number, let prompt, let answer):
            LessonTryItView(number: number, prompt: strippingLinks(from: prompt), answer: strippingLinks(from: answer))
        case .list(let ordered, let items):
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                        Text(ordered ? "\(index + 1)." : "•") // l10n: verbatim
                            .font(DesignTokens.FontScale.body.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                        Text(lessonEnglish(strippingLinks(from: item))) // l10n: content(en)
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
#if os(tvOS) || os(visionOS)
                            .fixedSize(horizontal: false, vertical: true)
#endif
                    }
                }
            }
        case .code(_, let text):
            ScrollView(.horizontal) {
                Text(lessonEnglish(text)) // l10n: content(en)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.ink)
#if os(iOS) || os(macOS)
                    .textSelection(.enabled)
#endif
                    .padding(DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
        case .table(let table):
#if os(iOS) || os(macOS)
            LessonTableView(table: table)
#else
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(lessonEnglish(table.headers.map { String($0.characters) }.joined(separator: " | "))) // l10n: content(en)
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    Text(lessonEnglish(row.map { String($0.characters) }.joined(separator: " | "))) // l10n: content(en)
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
#endif
        case .figure(let figure):
#if os(iOS) || os(macOS)
            LessonFigureView(figure: figure)
#else
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(lessonEnglish(figure.altText)) // l10n: content(en)
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                ForEach(Array(figure.textEquivalent.enumerated()), id: \.offset) { _, text in
                    Text(lessonEnglish(text)) // l10n: content(en)
                        .font(DesignTokens.FontScale.caption)
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
#endif
        case .illustrationBrief:
            EmptyView()
        case .blockquote(let text):
            Text(lessonEnglish(strippingLinks(from: text))) // l10n: content(en)
                .font(DesignTokens.FontScale.body.italic())
                .foregroundStyle(DesignTokens.Colors.ink)
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
#if os(iOS) || os(macOS)
                .textSelection(.enabled)
#else
                .fixedSize(horizontal: false, vertical: true)
#endif
        }
    }

    private func renderedMarkdown() -> RenderedLessonMarkdown {
        (try? LessonMarkdownRenderer.render(markdown)) ?? RenderedLessonMarkdown(blocks: [.paragraph(AttributedString(markdown))])
    }

    private func displayBlocks(_ rendered: RenderedLessonMarkdown) -> [DisplayLessonBlock] {
        let headingAnchors = LessonHeadingAnchors.anchorEntries(for: rendered, title: title)
        var headingIndex = 0
        return rendered.blocks.enumerated().map { offset, block in
            let headingAnchor: String?
            if case let .heading(level, text) = block {
                if level == 1, title != nil, plainString(text) == title {
                    headingAnchor = nil
                } else {
                    headingAnchor = headingAnchors[safe: headingIndex] ?? nil
                    headingIndex += 1
                }
            } else {
                headingAnchor = nil
            }
            return DisplayLessonBlock(id: offset, block: block, headingAnchor: headingAnchor, fallbackID: "lesson-block-\(offset)")
        }
    }

    @ViewBuilder
    private func headingView(level: Int, text: AttributedString, headingAnchor: String?, fallbackID: String) -> some View {
        let heading = Text(lessonEnglish(strippingLinks(from: text))) // l10n: content(en)
            .font(level <= 2 ? DesignTokens.FontScale.title.weight(.bold) : DesignTokens.FontScale.bodyLarge.weight(.bold))
            .foregroundStyle(DesignTokens.Colors.ink)
            .accessibilityAddTraits(.isHeader)
            .id(headingAnchor ?? fallbackID)
        if let headingAnchor {
            heading
                .accessibilityIdentifier("lesson-heading-\(headingAnchor)")
                .accessibilityFocused($focusedHeadingAnchor, equals: headingAnchor)
        } else {
            heading.accessibilityIdentifier("lesson-heading")
        }
    }

    private func focusTargetHeadingAfterLayout() {
        guard let targetAnchor else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            focusedHeadingAnchor = targetAnchor
#if os(tvOS)
            focusedBlockID = targetBlockID(for: targetAnchor)
#endif
        }
    }

#if os(tvOS)
    private func targetBlockID(for targetAnchor: String) -> Int? {
        displayBlocks(renderedMarkdown()).first { $0.headingAnchor == targetAnchor }?.id
    }
#endif

    private func strippingLinks(from value: AttributedString) -> AttributedString {
        var copy = value
        let ranges = copy.runs.map(\.range)
        for range in ranges {
            copy[range].link = nil
        }
        return copy
    }

    private func plainString(_ value: AttributedString) -> String {
        String(value.characters)
    }
}

private struct LessonTryItView: View {
    let number: Int
    let prompt: AttributedString
    let answer: AttributedString
    @State private var expanded = false
#if os(tvOS)
    @FocusState private var answerFocused: Bool
#endif

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                Text("\(number).") // l10n: verbatim
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                Text(lessonEnglish(prompt)) // l10n: content(en)
                    .font(DesignTokens.FontScale.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("lesson-try-it-\(number)-prompt")
            }
            Button {
#if os(tvOS)
                expanded = true
#else
                expanded.toggle()
#endif
            } label: {
                if expanded {
#if os(tvOS)
                    Text("Answer \(number)") // l10n: localized
#else
                    Text("Hide answer \(number)") // l10n: localized
#endif
                } else {
                    Text("Show answer \(number)") // l10n: localized
                }
            }
            .font(DesignTokens.FontScale.body.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
#if os(tvOS)
            .buttonStyle(TVSecondaryButtonStyle())
#else
            .buttonStyle(.bordered)
            .controlSize(.large)
#endif
            .accessibilityValue(expanded ? Text("Expanded") : Text("Collapsed")) // l10n: localized
            .accessibilityIdentifier("lesson-try-it-\(number)-toggle")
#if os(tvOS)
            .focused($answerFocused)
            .onChange(of: answerFocused) { _, focused in
                if focused { expanded = true }
            }
#endif
            if expanded {
                Text(lessonEnglish(answer)) // l10n: content(en)
                    .font(DesignTokens.FontScale.body)
                    .fixedSize(horizontal: false, vertical: true)
#if os(iOS) || os(macOS)
                    .textSelection(.enabled)
#endif
                    .accessibilityIdentifier("lesson-try-it-\(number)-answer")
            }
        }
        .foregroundStyle(DesignTokens.Colors.ink)
        .onChange(of: expanded) { _, shown in
            let announcement = shown ? String(localized: "Answer \(number) shown.") : String(localized: "Answer \(number) hidden.")
            AccessibilityNotification.Announcement(announcement).post()
        }
    }
}

private struct DisplayLessonBlock: Identifiable {
    let id: Int
    let block: LessonBlock
    let headingAnchor: String?
    let fallbackID: String
}

#if os(iOS) || os(macOS)
private struct LessonFigureView: View {
    let figure: MarkdownFigure
    @State private var showingEnlargedFigure = false

    private var aspectRatio: CGFloat {
        LessonFigureMetadata.aspectRatio(for: figure.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Button("Enlarge figure") {
                showingEnlargedFigure = true
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("lesson-figure-\(figure.id)-enlarge")

            Button {
                showingEnlargedFigure = true
            } label: {
                figureImage
                    .frame(maxWidth: .infinity)
                    .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(lessonEnglish(figure.altText))) // l10n: content(en)
            .accessibilityHint(Text("Opens enlarged figure")) // l10n: localized
            .accessibilityIdentifier("lesson-figure-\(figure.id)")

            if !figure.textEquivalent.isEmpty {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        ForEach(Array(figure.textEquivalent.enumerated()), id: \.offset) { index, item in
                            Text(lessonEnglish(item)) // l10n: content(en)
                                .font(DesignTokens.FontScale.body)
                                .foregroundStyle(DesignTokens.Colors.ink)
                                .textSelection(.enabled)
                                .accessibilityIdentifier("lesson-figure-\(figure.id)-text-equivalent-row-\(index)")
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.sm)
                } label: {
                    Text("Figure text equivalent")
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        .sheet(isPresented: $showingEnlargedFigure) {
            EnlargedLessonFigureView(figure: figure, aspectRatio: aspectRatio)
        }
    }

    private var figureImage: some View {
        Image("lesson-figure-\(figure.id)")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .aspectRatio(aspectRatio, contentMode: .fit)
            .foregroundStyle(DesignTokens.Colors.ink)
    }
}

private struct EnlargedLessonFigureView: View {
    let figure: MarkdownFigure
    let aspectRatio: CGFloat
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Enlarged figure") // l10n: localized
                    .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                Button {
                    dismiss()
                } label: {
                    Text("Done") // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)

            Divider()

            GeometryReader { geometry in
                let fitSize = fittedSize(in: geometry.size)
                ScrollView([.horizontal, .vertical]) {
                    Image("lesson-figure-\(figure.id)")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .frame(width: fitSize.width, height: fitSize.height)
                        .scaleEffect(scale)
                        .frame(width: fitSize.width * scale, height: fitSize.height * scale)
                        .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                        .accessibilityLabel(Text(lessonEnglish(figure.altText))) // l10n: content(en)
                        .accessibilityIdentifier("lesson-figure-\(figure.id)-enlarged-image")
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                scale = scale == 1 ? 2 : 1
                                lastScale = scale
                            }
                        }
                }
                .background(DesignTokens.Colors.paper)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = min(max(lastScale * value.magnification, 1), 4)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
            }
        }
        .background(DesignTokens.Colors.paper)
        .accessibilityIdentifier("lesson-figure-\(figure.id)-enlarged")
#if os(macOS)
        .frame(minWidth: 640, minHeight: 520)
#endif
    }

    private func fittedSize(in container: CGSize) -> CGSize {
        let availableWidth = max(1, container.width - DesignTokens.Spacing.xl * 2)
        let availableHeight = max(1, container.height - DesignTokens.Spacing.xl * 2)
        let availableAspectRatio = availableWidth / availableHeight
        if aspectRatio >= availableAspectRatio {
            return CGSize(width: availableWidth, height: availableWidth / aspectRatio)
        }
        return CGSize(width: availableHeight * aspectRatio, height: availableHeight)
    }
}

private struct LessonTableView: View {
    let table: MarkdownTable

    var body: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: DesignTokens.Spacing.md, verticalSpacing: DesignTokens.Spacing.sm) {
                GridRow {
                    ForEach(Array(table.headers.enumerated()), id: \.offset) { _, header in
                        Text(lessonEnglish(header)) // l10n: content(en)
                            .font(DesignTokens.FontScale.caption.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }
                }
                Divider().gridCellColumns(max(table.headers.count, 1))
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(lessonEnglish(cell)) // l10n: content(en)
                                .font(DesignTokens.FontScale.caption)
                                .foregroundStyle(DesignTokens.Colors.ink)
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Lesson table")
    }
}
#endif

private func lessonEnglish(_ string: String) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
    return attributedString
}

private func lessonEnglish(_ attributedString: AttributedString) -> AttributedString {
    var copy = attributedString
    copy.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
    return copy
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
