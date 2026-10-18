import CanadianHamContent
import SwiftUI

struct PlatformLessonMarkdownView: View {
    let lesson: Lesson
    let targetAnchor: String?

    @AccessibilityFocusState private var focusedHeadingAnchor: String?

    var body: some View {
        let rendered = (try? LessonMarkdownRenderer.render(lesson.bodyMarkdown)) ?? RenderedLessonMarkdown(blocks: [.paragraph(AttributedString(lesson.bodyMarkdown))])
        let blocks = displayBlocks(rendered, title: lesson.title.en)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(blocks) { displayBlock in
                blockView(displayBlock.block, headingAnchor: displayBlock.headingAnchor, fallbackID: displayBlock.fallbackID)
            }
        }
        .onAppear { focusTargetHeadingAfterLayout() }
        .onChange(of: targetAnchor) { _, _ in focusTargetHeadingAfterLayout() }
    }

    @ViewBuilder
    private func blockView(_ block: LessonBlock, headingAnchor: String?, fallbackID: String) -> some View {
        switch block {
        case .heading(let level, let text):
            if !(level == 1 && plainString(text) == lesson.title.en) {
                headingView(level: level, text: text, headingAnchor: headingAnchor, fallbackID: fallbackID)
            }
        case .paragraph(let text), .blockquote(let text):
            Text(platformEnglish(strippingLinks(from: text))) // l10n: content(en)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        case .list(let ordered, let items):
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                        Text(ordered ? "\(index + 1)." : "•") // l10n: verbatim
                            .font(DesignTokens.FontScale.body.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                        Text(platformEnglish(strippingLinks(from: item))) // l10n: content(en)
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        case .code(_, let text):
            ScrollView(.horizontal) {
                Text(platformEnglish(text)) // l10n: content(en)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .padding(DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
        case .table(let table):
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(platformEnglish(table.headers.map { String($0.characters) }.joined(separator: " | "))) // l10n: content(en)
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    Text(platformEnglish(row.map { String($0.characters) }.joined(separator: " | "))) // l10n: content(en)
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        case .figure(let figure):
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(platformEnglish(figure.altText)) // l10n: content(en)
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                ForEach(Array(figure.textEquivalent.enumerated()), id: \.offset) { _, text in
                    Text(platformEnglish(text)) // l10n: content(en)
                        .font(DesignTokens.FontScale.caption)
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        case .illustrationBrief:
            EmptyView()
        }
    }

    private func displayBlocks(_ rendered: RenderedLessonMarkdown, title: String?) -> [PlatformDisplayLessonBlock] {
        let headingAnchors = LessonHeadingAnchors.anchorEntries(for: rendered, title: title)
        var headingIndex = 0
        return rendered.blocks.enumerated().map { offset, block in
            let headingAnchor: String?
            if case let .heading(level, text) = block {
                if level == 1, let title, plainString(text) == title {
                    headingAnchor = nil
                } else {
                    headingAnchor = headingAnchors[safe: headingIndex] ?? nil
                    headingIndex += 1
                }
            } else {
                headingAnchor = nil
            }
            return PlatformDisplayLessonBlock(id: offset, block: block, headingAnchor: headingAnchor, fallbackID: "lesson-block-\(offset)")
        }
    }

    @ViewBuilder
    private func headingView(level: Int, text: AttributedString, headingAnchor: String?, fallbackID: String) -> some View {
        let heading = Text(platformEnglish(strippingLinks(from: text))) // l10n: content(en)
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
        }
    }

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

private struct PlatformDisplayLessonBlock: Identifiable {
    let id: Int
    let block: LessonBlock
    let headingAnchor: String?
    let fallbackID: String
}

private func platformEnglish(_ string: String) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = "en-CA"
    return attributedString
}

private func platformEnglish(_ attributedString: AttributedString) -> AttributedString {
    var copy = attributedString
    copy.languageIdentifier = "en-CA"
    return copy
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
