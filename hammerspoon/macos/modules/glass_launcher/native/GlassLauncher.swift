import AppKit
import ImageIO
import DiskArbitration
import SwiftUI
import QuickLookUI
import QuickLookThumbnailing

private let panelWidth: CGFloat = 660
private let searchHeight: CGFloat = 74
private let rowHeight: CGFloat = 60
private let resultPadding: CGFloat = 8
private let contextHeight: CGFloat = 72
private let historyRowHeight: CGFloat = 30
private let historyPadding: CGFloat = 8
private let resultLimit = 5
private let clipboardResultLimit = 12
private let clipboardRowHeight: CGFloat = 34
private let panelCornerRadius: CGFloat = 27

private struct SearchResult: Decodable {
    let id: Int
    let title: String
    let subtitle: String
    let path: String?
    let appIconPath: String?
    let hasAlternate: Bool?
    let status: String?
    let icon: String?
    let symbol: String?
    let symbolTile: UInt32?
    let swatch: UInt32?
    let previewText: String?
    let previewImage: String?
    let valid: Bool?
    let isDirectory: Bool?
    let storageUsed: Double?
}

private struct ActionContext: Decodable {
    let title: String
    let path: String?
}

private struct QueryHistoryEntry: Decodable {
    let query: String
    let timestamp: TimeInterval?

    func age(at now: Date) -> String? {
        guard let timestamp else { return nil }
        let minutes = Int(max(0, now.timeIntervalSince1970 - timestamp) / 60)
        switch minutes {
        case 0: return "<1min"
        case 1..<60: return "\(minutes)min"
        case 60..<1440: return "\(minutes / 60)h"
        default: return "\(minutes / 1440)d"
        }
    }
}

private struct SearchReply: Decodable {
    let deliveryID: Int?
    let panelCommand: String?
    let searchIcon: String?
    let lightMode: Bool?
    let request: Int
    let results: [SearchResult]?
    let placeholder: String?
    let resetQuery: String?
    let context: ActionContext?
    let closePreview: Bool?
    let clipboardMode: Bool?
    let history: [QueryHistoryEntry]?
    let navigationPrefix: String?
    let navigationMessage: String?
    let startupInput: String?
}

private struct SearchEvent: Encodable {
    let request: Int
    let query: String?
    let choice: Int?
    var back: Bool? = nil
    var fileAction: String? = nil
    var previewOpen: Bool? = nil
    var copyOnly: Bool? = nil
    var browseParent: Bool? = nil
    var startupReady: Bool? = nil
    var panelHidden: Bool? = nil
    var deliveryID: Int? = nil
}

@MainActor
private final class SearchModel: ObservableObject {
    @Published private(set) var searchIcon = CommandLine.arguments
        .first { $0.hasPrefix("--search-icon=") }
        .map { String($0.dropFirst("--search-icon=".count)) } ?? "magnifyingglass"
    @Published private(set) var lightMode = CommandLine.arguments.contains("--light-appearance")
    var updateAppearance: ((Bool) -> Void)?
    @Published private(set) var results: [SearchResult] = []
    @Published private(set) var selection = 0
    @Published private(set) var placeholder = "Search apps, files, and folders"
    @Published private(set) var resetQuery = ""
    @Published private(set) var input = ""
    @Published private(set) var isComposing = false
    @Published private(set) var context: ActionContext?
    @Published private(set) var clipboardMode = false
    @Published private(set) var navigationPrefix: String?
    @Published private(set) var navigationMessage: String?
    @Published private(set) var resetVersion = 0
    private var history: [QueryHistoryEntry] = []
    @Published private(set) var historyIndex: Int?
    var historyVisibleLimit = 5
    @Published private var firstVisibleIndex = 0
    private var request = 0
    private var displayedRequest = 0
    var resize: ((_ height: CGFloat, _ headerHeight: CGFloat) -> Void)?
    var visibleHistoryIndices: Range<Int> {
        guard let historyIndex else { return 0..<0 }
        let first = max(0, historyIndex - historyVisibleLimit + 1)
        return first..<min(first + historyVisibleLimit, history.count)
    }
    var headerHeight: CGFloat {
        if context != nil { return contextHeight }
        guard historyIndex != nil else { return 0 }
        return historyPadding + CGFloat(visibleHistoryIndices.count) * historyRowHeight
    }

    func historyEntry(at index: Int) -> QueryHistoryEntry { history[index] }
    var splitResults: Bool { clipboardMode || navigationPrefix != nil }
    var visibleLimit: Int { splitResults ? clipboardResultLimit : resultLimit }
    var shortcutLimit: Int { min(visibleLimit, 9) }
    var displayedRowHeight: CGFloat { splitResults ? clipboardRowHeight : rowHeight }
    var resultsHeight: CGFloat {
        let count = splitResults ? clipboardResultLimit : min(results.count, resultLimit)
        return count == 0 ? 0 : 2 * resultPadding + CGFloat(count) * displayedRowHeight
    }
    var height: CGFloat { searchHeight + headerHeight + resultsHeight }
    var visibleIndices: Range<Int> {
        firstVisibleIndex..<min(firstVisibleIndex + visibleLimit, results.count)
    }

    func setComposing(_ composing: Bool) {
        if isComposing != composing { isComposing = composing }
    }

    func search(_ query: String) {
        if historyIndex != nil {
            historyIndex = nil
            resize?(height, headerHeight)
        }
        submitQuery(query)
    }

    private func submitQuery(_ query: String) {
        input = query
        request += 1
        firstVisibleIndex = 0
        selection = 0
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            show([])
        }
        send(SearchEvent(request: request, query: query, choice: nil))
    }

    func apply(_ reply: SearchReply) {
        guard reply.request == request else { return }
        if let lightMode = reply.lightMode, lightMode != self.lightMode {
            self.lightMode = lightMode
            updateAppearance?(lightMode)
        }
        if let icon = reply.searchIcon, icon != searchIcon { searchIcon = icon }
        history = reply.history ?? []
        if let index = historyIndex, !history.indices.contains(index) { historyIndex = nil }
        if let text = reply.resetQuery {
            historyIndex = nil
            resetQuery = text
            input = text
            resetVersion += 1
            firstVisibleIndex = 0
            selection = 0
        } else if displayedRequest != request {
            firstVisibleIndex = 0
            selection = 0
        }
        if let label = reply.placeholder { placeholder = label }
        context = reply.context
        clipboardMode = reply.clipboardMode == true
        navigationPrefix = reply.navigationPrefix
        navigationMessage = reply.navigationMessage
        displayedRequest = request
        show(reply.results ?? [])
    }

    private func show(_ newResults: [SearchResult]) {
        firstVisibleIndex = min(firstVisibleIndex, max(0, newResults.count - visibleLimit))
        results = newResults
        selection = min(selection, max(0, results.count - 1))
        resize?(height, headerHeight)
    }

    func moveFromSearchField(_ offset: Int) {
        if let index = historyIndex {
            let next = min(index - offset, history.count - 1)
            historyIndex = next >= 0 ? next : nil
            resize?(height, headerHeight)
        } else if offset < 0, input.isEmpty, !history.isEmpty {
            historyIndex = 0
            resize?(height, headerHeight)
        } else {
            move(offset)
        }
    }

    func recallHistory(at index: Int) {
        guard historyIndex != nil, history.indices.contains(index) else { return }
        let query = history[index].query
        historyIndex = nil
        resetQuery = query
        resetVersion += 1
        resize?(height, headerHeight)
        submitQuery(query)
    }

    func move(_ offset: Int) {
        guard !results.isEmpty else { return }
        let next = (selection + offset + results.count) % results.count
        firstVisibleIndex = min(next, max(firstVisibleIndex, next - visibleLimit + 1))
        selection = next
    }

    func scrollResults(by rows: Int) {
        guard displayedRequest == request, !results.isEmpty, rows != 0 else { return }
        let next = min(max(0, firstVisibleIndex + rows), max(0, results.count - visibleLimit))
        guard next != firstVisibleIndex else { return }
        firstVisibleIndex = next
        selection = min(max(selection, next), visibleIndices.upperBound - 1)
    }

    func hover(row: Int) {
        let index = visibleIndices.lowerBound + row
        guard displayedRequest == request, visibleIndices.contains(index),
              results[index].valid != false || results[index].storageUsed != nil,
              selection != index else { return }
        selection = index
    }

    var selectedPath: String? {
        guard displayedRequest == request, results.indices.contains(selection),
              results[selection].valid != false else { return nil }
        return results[selection].path
    }

    func choose(_ index: Int? = nil, fileAction: String? = nil, copyOnly: Bool? = nil) {
        if let historyIndex, index == nil, fileAction == nil {
            recallHistory(at: historyIndex)
            return
        }
        let index = index ?? selection
        guard displayedRequest == request, results.indices.contains(index), results[index].valid != false else { return }
        let result = results[index]
        if fileAction == "enterFolder", result.isDirectory != true { return }
        if fileAction != nil, result.path == nil {
            let clipboardAction = fileAction == "actions" && clipboardMode &&
                (result.previewText != nil || result.previewImage != nil)
            let alternateAction = fileAction == "reveal" && result.hasAlternate == true
            guard clipboardAction || alternateAction else { return }
        }
        displayedRequest = -1
        send(SearchEvent(request: request, query: nil, choice: results[index].id, fileAction: fileAction, copyOnly: copyOnly))

    }

    func prepareForPresentation(request: Int) {
        self.request = request
    }

    func reportPanelHidden() {
        send(SearchEvent(request: request, query: nil, choice: nil, panelHidden: true))
    }

    func reportStartupReady() {
        send(SearchEvent(request: request, query: nil, choice: nil, startupReady: true))
    }

    func browseParent() {
        send(SearchEvent(request: request, query: nil, choice: nil, browseParent: true))
    }

    func reportPreview(open: Bool) {
        send(SearchEvent(request: request, query: nil, choice: nil, previewOpen: open))
    }

    func back() {
        if historyIndex != nil {
            historyIndex = nil
            resize?(height, headerHeight)
            return
        }
        send(SearchEvent(request: request, query: nil, choice: nil, back: true))
    }

    func acknowledgeDelivery(_ id: Int) {
        send(SearchEvent(request: request, query: nil, choice: nil, deliveryID: id))
    }

    private func send(_ event: SearchEvent) {
        guard var data = try? JSONEncoder().encode(event) else { return }
        data.append(0x0A)
        try? FileHandle.standardOutput.write(contentsOf: data)
    }
}

private final class CaretGlowView: NSView {
    static let padding: CGFloat = 12
    static let coreWidth: CGFloat = 2.25

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let beam = bounds.insetBy(dx: Self.padding, dy: Self.padding)
        let core = CGPath(roundedRect: beam, cornerWidth: 1, cornerHeight: 1, transform: nil)
        if effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua {
            context.setFillColor(NSColor(srgbRed: 0.11, green: 0.25, blue: 0.44, alpha: 1).cgColor)
            context.addPath(core)
            context.fillPath()
            return
        }
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ alpha: CGFloat) -> CGColor {
            NSColor(srgbRed: r, green: g, blue: b, alpha: alpha).cgColor
        }

        let cool = color(0.73, 0.91, 1, 0.96)
        for (blur, tint) in [(8.5, color(0.68, 0.86, 1, 0.74)), (5.0, cool)] {
            context.saveGState()
            context.setShadow(offset: .zero, blur: blur, color: tint)
            context.setFillColor(NSColor.white.cgColor)
            context.addPath(core)
            context.fillPath()
            context.restoreGState()
        }

        let warm = CGGradient(colorsSpace: space, colors: [
            color(1, 0.83, 0.59, 0.70), color(1, 0.83, 0.59, 0.23), color(1, 0.83, 0.59, 0)
        ] as CFArray, locations: [0, 0.43, 1])!
        let foot = CGPoint(x: beam.midX, y: beam.minY + 2)
        context.drawRadialGradient(warm, startCenter: foot, startRadius: 0,
                                   endCenter: foot, endRadius: 7.5, options: [])

        let white = NSColor.white.cgColor
        let filament = CGGradient(colorsSpace: space, colors: [
            color(1, 0.92, 0.76, 1), white, white, color(0.87, 0.97, 1, 1)
        ] as CFArray, locations: [0, 0.22, 0.79, 1])!
        context.addPath(core)
        context.clip()
        context.drawLinearGradient(filament, start: CGPoint(x: beam.midX, y: beam.minY),
                                   end: CGPoint(x: beam.midX, y: beam.maxY), options: [])
    }
}

private final class LauncherFieldEditor: NSTextView {
    var onCompositionChange: ((Bool) -> Void)?
    private var caretScrollPending = false

    private lazy var caretGlow: NSView = {
        let view = CaretGlowView(frame: .zero)
        view.wantsLayer = true
        view.layerContentsRedrawPolicy = .onSetNeedsDisplay
        view.isHidden = true
        return view
    }()

    override var shouldDrawInsertionPoint: Bool { false }

    override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else { return false }
        scrollSelectionToVisible()
        return true
    }

    override func updateInsertionPointStateAndRestartTimer(_ restartFlag: Bool) {
        super.updateInsertionPointStateAndRestartTimer(restartFlag)
        scrollSelectionToVisible()
    }

    private func updateCaretGlow(in clip: NSClipView, at rect: NSRect) {
        if caretGlow.superview !== clip {
            caretGlow.removeFromSuperview()
            clip.addSubview(caretGlow, positioned: .above, relativeTo: self)
        }
        let width = CaretGlowView.coreWidth
        let beam = NSRect(x: rect.midX - width / 2, y: rect.minY + 3, width: width, height: max(1, rect.height - 6))
        let frame = beam.insetBy(dx: -CaretGlowView.padding, dy: -CaretGlowView.padding)
        if caretGlow.frame.size != frame.size { caretGlow.needsDisplay = true }
        caretGlow.frame = frame
        caretGlow.isHidden = false

        let blink = CAKeyframeAnimation(keyPath: "opacity")
        blink.values = [1, 1, 0, 0, 1]
        blink.keyTimes = [0, 0.42, 0.65, 0.79, 1]
        blink.timingFunctions = [.init(name: .linear), .init(name: .easeInEaseOut),
                                 .init(name: .linear), .init(name: .easeInEaseOut)]
        blink.duration = 1.15
        blink.repeatCount = .infinity
        caretGlow.layer?.add(blink, forKey: "caretBlink")
    }

    override func resignFirstResponder() -> Bool {
        guard super.resignFirstResponder() else { return false }
        caretGlow.isHidden = true
        return true
    }

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
        scrollSelectionToVisible()
        reportComposition()
    }

    override func unmarkText() {
        super.unmarkText()
        reportComposition()
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        super.insertText(insertString, replacementRange: replacementRange)
        reportComposition()
    }

    override func didChangeText() {
        super.didChangeText()
        scrollSelectionToVisible()
    }

    override func doCommand(by selector: Selector) {
        let previousSelection = selectedRange()
        super.doCommand(by: selector)
        if selectedRange() != previousSelection {
            scrollSelectionToVisible()
        }
    }

    func scrollSelectionToVisible() {
        guard !caretScrollPending else { return }
        caretScrollPending = true
        // Let AppKit update the editor's document width before scrolling.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.caretScrollPending = false
            guard let window = self.window, window.firstResponder === self else { return }
            let selection = self.selectedRange()
            let clip = self.superview as? NSClipView
            // The editor's clip view extends slightly past the text field itself.
            let trailingSpace: CGFloat = 16
            if let clip, clip.contentInsets.right != trailingSpace {
                var insets = clip.contentInsets
                insets.right = trailingSpace
                clip.contentInsets = insets
            }
            self.scrollRangeToVisible(selection)
            guard window.isKeyWindow, selection.length == 0, let clip else {
                self.caretGlow.isHidden = true
                return
            }

            let caret = self.firstRect(forCharacterRange: selection, actualRange: nil)
            guard caret.height > 0 else {
                self.caretGlow.isHidden = true
                return
            }
            let caretInClip = clip.convert(window.convertFromScreen(caret), from: nil)
            let overflow = caretInClip.maxX + trailingSpace - clip.bounds.maxX
            if overflow > 0 {
                clip.scroll(to: NSPoint(x: clip.bounds.minX + ceil(overflow), y: clip.bounds.minY))
            }
            self.updateCaretGlow(in: clip, at: clip.convert(window.convertFromScreen(
                self.firstRect(forCharacterRange: selection, actualRange: nil)), from: nil))
        }
    }

    private func reportComposition() {
        onCompositionChange?(hasMarkedText())
    }
}

private final class LauncherTextField: NSTextField {
    var onEdit: ((String) -> Void)?

    override func textDidBeginEditing(_ notification: Notification) {
        super.textDidBeginEditing(notification)
        guard let editor = currentEditor() as? NSTextView else { return }
        editor.enabledTextCheckingTypes = 0
        editor.isAutomaticTextCompletionEnabled = false
        editor.inlinePredictionType = .no
        editor.mathExpressionCompletionType = .no
    }

    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        let editor = currentEditor() as? NSTextView
        guard editor?.hasMarkedText() != true else { return }
        onEdit?(editor?.string ?? stringValue)
    }
}

private struct SearchField: NSViewRepresentable {
    @ObservedObject var model: SearchModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeNSView(context: Context) -> NSTextField {
        let field = LauncherTextField()
        field.onEdit = { [weak model] in model?.search($0) }
        field.font = .systemFont(ofSize: 28)
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.lineBreakMode = .byClipping
        field.usesSingleLineMode = true
        field.cell?.isScrollable = true
        field.isAutomaticTextCompletionEnabled = false
        field.allowsWritingTools = false
        field.setAccessibilityLabel("Search apps, files, and folders")
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        field.setAccessibilityLabel(model.placeholder)
        guard context.coordinator.resetVersion != model.resetVersion else { return }
        context.coordinator.resetVersion = model.resetVersion
        // End the old editing session before installing the next view's query.
        // Otherwise AppKit can retain the previous text in its shared field editor.
        field.abortEditing()
        field.stringValue = model.resetQuery
        field.selectText(nil)
        if let editor = field.currentEditor() as? LauncherFieldEditor {
            let caret = NSRange(location: model.resetQuery.utf16.count, length: 0)
            editor.setSelectedRange(caret)
            editor.scrollSelectionToVisible()
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        let model: SearchModel
        var resetVersion = 0
        init(model: SearchModel) { self.model = model }

        func control(
            _ control: NSControl, textView: NSTextView, doCommandBy command: Selector
        ) -> Bool {
            guard !textView.hasMarkedText() else { return false }
            switch command {
            case #selector(NSResponder.moveUp(_:)): model.moveFromSearchField(-1)
            case #selector(NSResponder.moveDown(_:)): model.moveFromSearchField(1)
            case #selector(NSResponder.insertNewline(_:)): model.choose()
            case #selector(NSResponder.cancelOperation(_:)): model.back()
            case #selector(NSTextView.complete(_:)): break
            default: return false
            }
            return true
        }
    }
}

private struct FileBrowserPreview: View {
    let path: String
    let icon: NSImage
    let isDirectory: Bool
    @MainActor private final class PreviewData: ObservableObject {
        @Published var thumbnail: NSImage?
        @Published var metadata: URLResourceValues?
    }

    @StateObject private var data = PreviewData()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(nsImage: data.thumbnail ?? icon)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: data.thumbnail == nil ? 192 : .infinity,
                       maxHeight: data.thumbnail == nil ? 192 : .infinity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Selected item preview")
            if let created = data.metadata?.creationDate {
                Text("Created \(created.formatted(date: .abbreviated, time: .shortened))")
            }
            if let modified = data.metadata?.contentModificationDate {
                Text("Modified \(modified.formatted(date: .abbreviated, time: .shortened))")
            }
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .task(id: path) {
            data.thumbnail = nil
            let url = URL(fileURLWithPath: path)
            data.metadata = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            guard !isDirectory else { return }
            let request = QLThumbnailGenerator.Request(
                fileAt: url, size: CGSize(width: 300, height: 330), scale: 2, representationTypes: .thumbnail
            )
            if let image = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request),
               !Task.isCancelled {
                data.thumbnail = image.nsImage
            }
        }
    }
}

private struct ClipboardTextPreview: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.drawsBackground = false
        scroll.autohidesScrollers = true
        if let view = scroll.documentView as? NSTextView {
            view.isEditable = false
            view.isSelectable = true
            view.drawsBackground = false
            view.font = .systemFont(ofSize: 15)
            view.textColor = .labelColor
            view.textContainerInset = NSSize(width: 0, height: 4)
            view.setAccessibilityLabel("Clipboard text preview")
        }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let view = scroll.documentView as? NSTextView, view.string != text else { return }
        view.string = text
        view.scrollRangeToVisible(NSRange(location: 0, length: 0))
    }
}

private struct LauncherView: View {
    @ObservedObject var model: SearchModel

    private var ruleColor: Color { model.lightMode ? .black.opacity(0.14) : .white.opacity(0.15) }
    private var selectionColor: Color { model.lightMode ? .black.opacity(0.13) : .white.opacity(0.17) }
    private var subtitleColor: Color { model.lightMode ? .black.opacity(0.72) : .white.opacity(0.82) }

    var body: some View {
        VStack(spacing: 0) {
            if let context = model.context {
                contextHeader(context)
                    .overlay(alignment: .bottom) { separator }
            } else if model.historyIndex != nil {
                historyList.overlay(alignment: .bottom) { separator }
            }
            HStack(spacing: 16) {
                Image(systemName: model.searchIcon)
                    .font(.system(size: 24, weight: .medium))
                    .frame(width: 28)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                SearchField(model: model)
                .frame(height: 36)
            }
            .padding(.horizontal, 23)
            .frame(height: searchHeight)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                if model.splitResults || !model.results.isEmpty { separator }
            }

            if model.results.isEmpty &&
                (model.navigationPrefix != nil || (model.clipboardMode && model.navigationMessage != nil)) {
                Text(model.navigationMessage ?? "No item")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(width: panelWidth, height: model.resultsHeight)
            } else if model.splitResults {
                HStack(alignment: .top, spacing: 0) {
                    resultList.frame(width: panelWidth / 2)
                    Rectangle()
                        .fill(ruleColor)
                        .frame(width: 1)
                        .padding(.vertical, resultPadding)
                    Group {
                        if model.results.indices.contains(model.selection) {
                            let result = model.results[model.selection]
                            if model.navigationPrefix != nil, let path = result.path {
                                FileBrowserPreview(path: path, icon: fileIcon(at: path), isDirectory: result.isDirectory == true)
                                    .id(path)
                            } else if model.clipboardMode {
                                clipboardPreview(result)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(14)
                }
                .frame(height: model.resultsHeight)
            } else if !model.results.isEmpty {
                resultList
            }
        }
        .frame(width: panelWidth)
        .background {
            let shape = RoundedRectangle(cornerRadius: panelCornerRadius)
            shape.fill(model.lightMode ? .white.opacity(0.86) : .black.opacity(0.74))
                .glassEffect(.clear, in: shape)
                .overlay { shape.strokeBorder(ruleColor, lineWidth: 1) }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .environment(\.colorScheme, model.lightMode ? .light : .dark)
    }

    private var historyList: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.visibleHistoryIndices.reversed()), id: \.self) { index in
                Button { model.recallHistory(at: index) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        let entry = model.historyEntry(at: index)
                        Text(entry.query).lineLimit(1).truncationMode(.middle)
                        Spacer(minLength: 0)
                        if entry.timestamp != nil {
                            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                                Text(entry.age(at: timeline.date) ?? "")
                                    .font(.system(size: 12))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .fixedSize()
                            }
                        }
                    }
                    .font(.system(size: 15))
                    .padding(.horizontal, 13)
                    .frame(height: historyRowHeight)
                    .contentShape(Rectangle())
                    .background {
                        if model.historyIndex == index {
                            RoundedRectangle(cornerRadius: 10).fill(selectionColor)
                        }
                    }
                    .accessibilityAddTraits(model.historyIndex == index ? .isSelected : [])
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, resultPadding)
        .padding(.top, historyPadding)
    }

    private var resultList: some View {
        VStack(spacing: 0) {
            ForEach(model.visibleIndices, id: \.self) { index in
                Button { model.choose(index) } label: {
                    resultRow(
                        model.results[index],
                        selected: model.selection == index,
                        shortcut: index - model.visibleIndices.lowerBound + 1
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(resultPadding)
    }

    @ViewBuilder
    private func clipboardPreview(_ result: SearchResult) -> some View {
        if let text = result.previewText {
            ClipboardTextPreview(text: text)
        } else if let path = result.previewImage,
                  let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Clipboard image preview")
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(ruleColor)
            .frame(height: 1)
            .padding(.horizontal, 20)
            .allowsHitTesting(false)
    }

    private func contextHeader(_ context: ActionContext) -> some View {
        HStack(spacing: 14) {
            Group {
                if let path = context.path {
                    Image(nsImage: fileIcon(at: path))
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "quote.opening").font(.system(size: 22, weight: .medium))
                }
            }
            .frame(width: 34, height: 34)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(context.title)
                    .font(.system(size: 18, weight: .medium))
                    .lineLimit(context.path == nil ? 2 : 1)
                if let path = context.path {
                    Text(path)
                        .font(.system(size: 14))
                        .foregroundStyle(subtitleColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 23)
        .frame(height: contextHeight)
        .accessibilityElement(children: .combine)
    }

    private func fileIcon(at path: String) -> NSImage {
        let iconPath = path.hasSuffix(".app") ? URL(fileURLWithPath: path).resolvingSymlinksInPath().path : path
        return NSWorkspace.shared.icon(forFile: iconPath)
    }

    private func resultRow(_ result: SearchResult, selected: Bool, shortcut: Int) -> some View {
        let iconSize: CGFloat = model.splitResults ? 22 : 38
        return HStack(spacing: model.splitResults ? 8 : 12) {
            Group {
                if let swatch = result.swatch {
                    let shape = RoundedRectangle(cornerRadius: 7)
                    shape.fill(Color(
                        red: Double((swatch >> 16) & 255) / 255,
                        green: Double((swatch >> 8) & 255) / 255,
                        blue: Double(swatch & 255) / 255
                    ))
                    .overlay { shape.strokeBorder(model.lightMode ? .black.opacity(0.22) : .white.opacity(0.42), lineWidth: 1) }
                } else if result.status == "focusOn" || result.status == "focusOff" {
                    let enabled = result.status == "focusOn"
                    Image(systemName: result.symbol ?? "moon.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(enabled ? Color.white : Color.primary)
                        .frame(width: iconSize, height: iconSize)
                        .background(enabled ? Color.accentColor : ruleColor, in: Circle())
                } else if result.status == "caffeineOn" || result.status == "caffeineOff" {
                    let isHot = result.status == "caffeineOn"
                    VStack(spacing: 1) {
                        Image(systemName: "heat.waves")
                            .font(.system(size: 10, weight: .medium))
                            .opacity(isHot ? 1 : 0)
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 23))
                            .overlay(alignment: .topLeading) {
                                if isHot {
                                    Capsule()
                                        .frame(width: 10, height: 2)
                                        .offset(x: 4, y: 4)
                                }
                            }
                    }
                    .foregroundStyle(.primary)
                } else if let symbol = result.symbol, let tile = result.symbolTile {
                    let base = Color(red: Double((tile >> 16) & 255) / 255,
                                     green: Double((tile >> 8) & 255) / 255,
                                     blue: Double(tile & 255) / 255)
                    let size = iconSize * 0.83
                    let shape = RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.55, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: 0.6, y: 1)
                        .frame(width: size, height: size)
                        .background {
                            shape.fill(base.gradient)
                        }
                        .overlay {
                            shape.strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                        }
                } else if let symbol = result.symbol {
                    Image(systemName: symbol).font(.system(size: model.splitResults ? 15 : 25))
                } else if let path = result.appIconPath ?? result.path {
                    Image(nsImage: fileIcon(at: path)).resizable()
                } else if let icon = result.icon.flatMap(NSImage.init(contentsOfFile:)) {
                    Image(nsImage: icon).resizable()
                } else {
                    Image(systemName: "arrow.up.forward.app").resizable()
                }
            }
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: model.splitResults ? 1 : 3) {
                Text(result.title).font(.system(size: model.splitResults ? 15 : 18, weight: .medium)).lineLimit(1)
                if !result.subtitle.isEmpty {
                    HStack(spacing: 4) {
                        if result.status == "live" {
                            LiveSignalIcon()
                        } else if result.status == "offline" {
                            Image(systemName: "zzz").accessibilityHidden(true)
                        }
                        Text(result.subtitle).lineLimit(1).truncationMode(.middle)
                    }
                    .font(.system(size: model.splitResults ? 10 : 14))
                    .foregroundStyle(subtitleColor)
                }
            }
            Spacer(minLength: 10)
            if result.status == "focusOn" {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
            if let used = result.storageUsed {
                ProgressView(value: used)
                    .progressViewStyle(.linear)
                    .tint(used >= 0.95 ? .red : used >= 0.85 ? .orange : .accentColor)
                    .frame(width: 180)
                    .accessibilityLabel("Storage used")
            }
            if selected, result.storageUsed == nil {
                Image(systemName: "return")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            } else if result.valid != false, shortcut <= model.shortcutLimit {
                Text("⌘\(shortcut)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .accessibilityLabel("Command \(shortcut)")
            }
        }
        .padding(.horizontal, 13)
        .frame(height: model.displayedRowHeight)
        .contentShape(Rectangle())
        .background {
            if selected {
                RoundedRectangle(cornerRadius: model.splitResults ? 10 : panelCornerRadius - resultPadding)
                    .fill(selectionColor)
            }
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct LiveSignalIcon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let green = Color(red: 92.0 / 255, green: 222.0 / 255, blue: 128.0 / 255)
    private static let period: TimeInterval = 3.15

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion)) { timeline in
            let phase = reduceMotion ? 0.16 : timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: Self.period) / Self.period
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let scale = min(size.width / 22, size.height / 18)
                let dotRadius = 2.5 * scale
                let dot = CGRect(x: center.x - dotRadius, y: center.y - dotRadius,
                                 width: 2 * dotRadius, height: 2 * dotRadius)
                context.fill(Path(ellipseIn: dot), with: .color(Self.green))

                drawWave(in: context, center: center, scale: scale, radius: 5.8, phase: phase)
                drawWave(in: context, center: center, scale: scale, radius: 9.4, phase: phase - 0.32)
            }
        }
        .frame(width: 16, height: 14)
        .accessibilityHidden(true)
    }

    private func drawWave(
        in context: GraphicsContext, center: CGPoint, scale: CGFloat, radius: CGFloat, phase: Double
    ) {
        let opacity = 0.26 + 0.74 * pow(0.5 + 0.5 * cos(2 * .pi * phase), 1.5)
        let reach = radius * scale
        let height = reach * 0.71
        var wave = Path()
        for side: CGFloat in [-1, 1] {
            let x = center.x + side * reach * 0.72
            wave.move(to: CGPoint(x: x, y: center.y - height))
            wave.addQuadCurve(to: CGPoint(x: x, y: center.y + height),
                              control: CGPoint(x: center.x + side * reach * 1.31, y: center.y))
        }
        context.stroke(wave, with: .color(Self.green.opacity(opacity)),
                       style: StrokeStyle(lineWidth: 1.7 * scale, lineCap: .round))
    }
}

private struct LargeTypeView: View {
    let text: String
    let fontSize: CGFloat
    let scrolls: Bool
    let lightMode: Bool

    var body: some View {
        Group {
            if scrolls {
                ScrollView { message.padding(.vertical, 30) }
            } else {
                message.padding(.vertical, 30)
            }
        }
        .padding(.horizontal, 42)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            let shape = RoundedRectangle(cornerRadius: panelCornerRadius)
            shape.fill(lightMode ? .white.opacity(0.92) : .black.opacity(0.88))
                .glassEffect(.clear, in: shape)
                .overlay { shape.strokeBorder(lightMode ? .black.opacity(0.14) : .white.opacity(0.16), lineWidth: 1) }
        }
    }

    private var message: some View {
        Text(verbatim: text)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(lightMode ? .black : .white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

// Keep a hit-testable backing across the panel, including gaps in the SwiftUI view.
private final class SearchPanelContent: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) ?? (frame.contains(point) ? self : nil)
    }

    override func scrollWheel(with event: NSEvent) {}
}

private final class SearchPanel: NSPanel, QLPreviewPanelDataSource {
    var previewURL: NSURL?

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool { true }

    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = self
    }

    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = nil
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURL == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        previewURL
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
private final class Launcher: NSObject, NSApplicationDelegate, NSWindowDelegate, @preconcurrency QLPreviewPanelDelegate {
    let model = SearchModel()
    private lazy var searchEditor: LauncherFieldEditor = {
        let editor = LauncherFieldEditor(frame: .zero)
        editor.isFieldEditor = true
        editor.onCompositionChange = { [weak model] composing in model?.setComposing(composing) }
        return editor
    }()
    private var panel: SearchPanel?
    private var searchContent: NSView?
    private var searchFrame: NSRect?
    private var searchTop: CGFloat = 0
    private var activePreview: QLPreviewPanel?
    private let resident = CommandLine.arguments.contains("--resident")
    private var waitingForStartupInput = CommandLine.arguments.contains("--buffer-startup")
    private var startupEvents: [NSEvent] = []
    private var reportedStartupReady = false

    private var keyMonitor: Any?
    private var pointerTimer: Timer?
    private var modifierTap: UInt16?
    private var lastPointerLocation = NSEvent.mouseLocation
    private var resultScrollRemainder: CGFloat = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        let view = LauncherView(model: model)
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let area = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 720)
        let top = (area.maxY - area.height * 0.22).rounded()
        searchTop = top
        model.historyVisibleLimit = max(1, min(5, Int((area.maxY - top - historyPadding) / historyRowHeight)))
        let rect = NSRect(
            x: area.midX - panelWidth / 2, y: top - searchHeight,
            width: panelWidth, height: searchHeight
        )
        let clipboardLaunch = CommandLine.arguments.contains("--clipboard")
        let style: NSWindow.StyleMask = clipboardLaunch ? .borderless : [.borderless, .nonactivatingPanel]
        let panel = SearchPanel(
            contentRect: rect, styleMask: style,
            backing: .buffered, defer: false
        )
        self.panel = panel
        panel.appearance = NSAppearance(named: model.lightMode ? .aqua : .darkAqua)
        model.updateAppearance = { [weak panel] lightMode in
            panel?.appearance = NSAppearance(named: lightMode ? .aqua : .darkAqua)
        }
        panel.title = "Main Chooser"
        panel.delegate = self
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = false
        panel.hasShadow = true
        panel.acceptsMouseMovedEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        let content = SearchPanelContent(frame: NSRect(origin: .zero, size: rect.size))
        // Clip the native backdrop as well as the SwiftUI content during the first layout.
        content.wantsLayer = true
        content.layer?.cornerRadius = panelCornerRadius
        content.layer?.cornerCurve = .continuous
        content.layer?.masksToBounds = true
        let hosting = NSHostingView(rootView: view.frame(maxHeight: .infinity, alignment: .top))
        hosting.sizingOptions = []
        hosting.frame = content.bounds
        hosting.autoresizingMask = [.width, .height]
        content.addSubview(hosting)
        panel.contentView = content
        installEditMenu()

        model.resize = { [weak self, weak panel] height, headerHeight in
            guard let self, let panel else { return }
            var frame = self.searchFrame ?? panel.frame
            frame.origin.y = self.searchTop + headerHeight - height
            frame.size.height = height
            if self.searchContent != nil {
                self.searchFrame = frame
            } else if frame != panel.frame {
                panel.setFrame(frame, display: true)
            }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel]
        ) { [weak self] event in
            guard let self else { return event }
            if self.waitingForStartupInput, event.type == .keyDown {
                if self.startupEvents.count < 512 { self.startupEvents.append(event) }
                return nil
            }
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control, .function])
            let isLargeTypeShortcut = event.type == .keyDown && flags == .command
                && event.charactersIgnoringModifiers?.lowercased() == "l"
            if self.searchContent != nil {
                if event.type == .keyDown {
                    if !event.isARepeat && (event.keyCode == 53 || isLargeTypeShortcut) {
                        self.dismissLargeType()
                    }
                    return nil
                }
                return event
            }
            if isLargeTypeShortcut, self.panel?.isKeyWindow == true {
                if !event.isARepeat { self.showLargeType() }
                return nil
            }
            if event.type == .flagsChanged {
                let key = event.keyCode
                let control = key == 59 || key == 62
                let shift = key == 56 || key == 60
                if flags.isEmpty, self.modifierTap == key {
                    self.modifierTap = nil
                    if control, self.panel?.isKeyWindow == true {
                        self.model.choose(fileAction: "actions")
                    } else if shift {
                        self.togglePreview()
                    }
                } else {
                    self.modifierTap = (control && flags == .control || shift && flags == .shift) ? key : nil
                }
                return event
            }
            self.modifierTap = nil
            if self.closePreviewOnEscape(event) { return nil }
            if event.type == .scrollWheel, self.scrollResults(with: event) { return nil }
            if event.type == .keyDown, event.keyCode == 126,
               flags.subtracting(.function).isEmpty,
               self.panel?.isKeyWindow == true, self.model.input.isEmpty,
               !self.searchEditor.hasMarkedText() {
                self.model.moveFromSearchField(-1)
                return nil
            }
            if event.type == .keyDown, let panel = self.panel, panel.isKeyWindow,
               panel.firstResponder === self.searchEditor, !self.searchEditor.hasMarkedText(),
               let key = event.charactersIgnoringModifiers?.lowercased() {
                switch (key, flags) {
                case ("u", .control):
                    if !self.searchEditor.string.isEmpty {
                        self.searchEditor.selectAll(nil)
                        self.searchEditor.deleteBackward(nil)
                    }
                    return nil
                case ("m", .control):
                    if !event.isARepeat { self.model.choose() }
                    return nil
                case ("f", .option):
                    self.searchEditor.moveWordForward(nil)
                    return nil
                case ("b", .option):
                    self.searchEditor.moveWordBackward(nil)
                    return nil
                default:
                    break
                }
            }
            if event.type == .keyDown, let prefix = self.model.navigationPrefix,
               self.panel?.isKeyWindow == true, !self.searchEditor.hasMarkedText() {
                var handled = true
                switch (event.keyCode, flags.subtracting(.function)) {
                case (123, []): self.model.browseParent()
                case (124, []): self.model.choose(fileAction: "browse")
                case (125, .command): self.model.choose(fileAction: "enterFolder")
                case (48, []): self.model.choose(fileAction: "completePath")
                case (51, []) where self.model.input == prefix: self.model.browseParent()
                case (31, .command): self.model.choose(fileAction: "openPath")
                default: handled = false
                }
                if handled { return nil }
            }
            if event.type == .keyDown, flags.isEmpty, event.keyCode == 53,
               self.model.clipboardMode, !self.searchEditor.hasMarkedText() {
                self.model.back()
                return nil
            }
            if event.type == .keyDown, self.model.clipboardMode, self.panel?.isKeyWindow == true,
               (event.keyCode == 36 || event.keyCode == 76), (flags.isEmpty || flags == .command),
               !self.searchEditor.hasMarkedText() {
                self.model.choose(copyOnly: flags == .command)
                return nil
            }
            if event.type == .keyDown, flags == .command, self.panel?.isKeyWindow == true {
                if event.keyCode == 36 || event.keyCode == 76 {
                    self.model.choose(fileAction: "reveal")
                    return nil
                }
                if let key = event.charactersIgnoringModifiers,
                   let index = Int(key), (1...self.model.shortcutLimit).contains(index) {
                    self.model.choose(self.model.visibleIndices.lowerBound + index - 1)
                    return nil
                }
            }
            return event
        }

        // Track the pointer even when the window underneath receives the mouse event.
        let pointerTimer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateHover(at: NSEvent.mouseLocation) }
        }
        self.pointerTimer = pointerTimer
        RunLoop.main.add(pointerTimer, forMode: .common)

        hosting.layoutSubtreeIfNeeded()
        if resident {
            pointerTimer.fireDate = .distantFuture
            warmResidentLayout(hosting)
        } else {
            if let field = findTextField(in: hosting) { panel.makeFirstResponder(field) }
            panel.orderFrontRegardless()
            if clipboardLaunch { NSApp.activate(ignoringOtherApps: true) }
            panel.makeKey()
            reportStartupReadyIfKey()
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let decoder = JSONDecoder()
            while let line = readLine() {
                guard let reply = try? decoder.decode(SearchReply.self, from: Data(line.utf8)) else { continue }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    defer {
                        if let id = reply.deliveryID { self.model.acknowledgeDelivery(id) }
                    }
                    if self.resident, reply.panelCommand == "show" {
                        self.showResidentPanel(reply)
                        return
                    } else if self.resident, reply.panelCommand == "hide" {
                        self.hideResidentPanel()
                        return
                    }
                    if let input = reply.startupInput, self.waitingForStartupInput {
                        self.model.apply(reply)
                        self.waitingForStartupInput = false
                        if !input.isEmpty {
                            self.searchEditor.insertText(input, replacementRange: self.searchEditor.selectedRange())
                        }
                        for event in self.startupEvents.reversed() { NSApp.postEvent(event, atStart: true) }
                        self.startupEvents.removeAll()
                    } else if reply.closePreview == true {
                        self.closeActivePreview()
                    } else {
                        self.model.apply(reply)
                    }
                }
            }
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    private func warmResidentLayout(_ hosting: NSView) {
        // Lay out each presentation before the first shortcut. The panel stays hidden.
        let layouts = [
            #"{"request":0,"clipboardMode":true,"results":[{"id":1,"title":"Clipboard","subtitle":"","previewText":" "}]}"#,
            #"{"request":0}"#,
        ]
        let decoder = JSONDecoder()
        for layout in layouts {
            guard let reply = try? decoder.decode(SearchReply.self, from: Data(layout.utf8)) else { continue }
            model.apply(reply)
            hosting.layoutSubtreeIfNeeded()
            hosting.displayIfNeeded()
        }
    }

    private func showLargeType() {
        guard let panel, let content = panel.contentView, let screen = panel.screen,
              !searchEditor.hasMarkedText(),
              !model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let text = model.input
        let area = screen.visibleFrame
        let maxWidth = area.width * 0.84
        let maxHeight = area.height * 0.68
        let textWidth = max(1, maxWidth - 84)
        let textHeight = max(1, maxHeight - 60)
        func measure(_ size: CGFloat) -> NSSize {
            (text as NSString).boundingRect(
                with: NSSize(width: textWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: NSFont.systemFont(ofSize: size, weight: .medium)]
            ).size
        }
        var lower = 22
        var upper = 160
        while lower < upper {
            let middle = (lower + upper + 1) / 2
            if measure(CGFloat(middle)).height <= textHeight {
                lower = middle
            } else {
                upper = middle - 1
            }
        }
        let size = measure(CGFloat(lower))
        let scrolls = size.height > textHeight
        let width = min(maxWidth, ceil(size.width) + 84)
        let height = min(maxHeight, ceil(size.height) + 60)

        searchContent = content
        searchFrame = panel.frame
        panel.makeFirstResponder(nil)
        panel.title = "Large Type"
        let view = NSHostingView(rootView: LargeTypeView(text: text, fontSize: CGFloat(lower), scrolls: scrolls, lightMode: model.lightMode))
        view.sizingOptions = []
        view.frame = NSRect(x: 0, y: 0, width: width, height: height)
        view.autoresizingMask = [.width, .height]
        panel.contentView = view
        panel.setFrame(NSRect(x: (area.midX - width / 2).rounded(), y: (area.midY - height / 2).rounded(),
                              width: width, height: height), display: true)
    }

    private func dismissLargeType() {
        guard let panel, let searchContent, let searchFrame else { return }
        panel.contentView = searchContent
        panel.title = "Main Chooser"
        panel.setFrame(searchFrame, display: true)
        self.searchContent = nil
        self.searchFrame = nil
        if let field = findTextField(in: searchContent) {
            field.stringValue = model.input
            field.selectText(nil)
            field.currentEditor()?.selectedRange = NSRange(location: model.input.utf16.count, length: 0)
        }
    }

    private func scrollResults(with event: NSEvent) -> Bool {
        guard let panel, event.window === panel, activePreview == nil else { return false }
        let point = panel.convertPoint(toScreen: event.locationInWindow)
        let listWidth = model.splitResults ? panel.frame.width / 2 : panel.frame.width
        let y = panel.frame.maxY - point.y - model.headerHeight - searchHeight
        guard point.x >= panel.frame.minX, point.x < panel.frame.minX + listWidth,
              y >= 0, y < model.resultsHeight else {
            resultScrollRemainder = 0
            return false
        }
        if event.phase == .began || event.phase == .cancelled { resultScrollRemainder = 0 }
        let delta = event.scrollingDeltaY
        if event.hasPreciseScrollingDeltas {
            if delta * resultScrollRemainder < 0 { resultScrollRemainder = 0 }
            resultScrollRemainder -= delta
            let rows = Int(resultScrollRemainder / model.displayedRowHeight)
            resultScrollRemainder -= CGFloat(rows) * model.displayedRowHeight
            model.scrollResults(by: rows)
        } else if delta != 0 {
            model.scrollResults(by: delta > 0 ? -1 : 1)
        }
        return true
    }

    private func updateHover(at location: NSPoint) {
        guard location != lastPointerLocation else { return }
        lastPointerLocation = location
        guard searchContent == nil, let panel, panel.isKeyWindow, panel.isVisible,
              panel.frame.contains(location) else { return }
        let x = location.x - panel.frame.minX
        let rowsTop = searchHeight + model.headerHeight + resultPadding
        let offset = panel.frame.maxY - location.y - rowsTop
        let listWidth = model.splitResults ? panel.frame.width / 2 : panel.frame.width
        guard x >= resultPadding, x < listWidth - resultPadding, offset >= 0 else { return }
        model.hover(row: Int(offset / model.displayedRowHeight))
    }

    private func togglePreview() {
        guard let panel else { return }
        if activePreview != nil {
            closeActivePreview()
            return
        }
        guard panel.isKeyWindow, let path = model.selectedPath,
              let preview = QLPreviewPanel.shared() else { return }
        activePreview = preview
        panel.previewURL = NSURL(fileURLWithPath: path)
        preview.updateController()
        preview.delegate = self
        preview.reloadData()
        if preview.level.rawValue < panel.level.rawValue { preview.level = panel.level }
        preview.makeKeyAndOrderFront(nil)
        model.reportPreview(open: true)
    }

    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        client is LauncherTextField ? searchEditor : nil
    }

    private func reportStartupReadyIfKey() {
        guard waitingForStartupInput, !reportedStartupReady, panel?.isKeyWindow == true else { return }
        reportedStartupReady = true
        model.reportStartupReady()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        reportStartupReadyIfKey()
    }

    private func showResidentPanel(_ reply: SearchReply) {
        guard let panel, let content = panel.contentView else { return }
        model.prepareForPresentation(request: reply.request)
        model.apply(reply)
        if let area = (NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main)?.visibleFrame {
            let top = (area.maxY - area.height * 0.22).rounded()
            model.historyVisibleLimit = max(1, min(5, Int((area.maxY - top - historyPadding) / historyRowHeight)))
            searchTop = top
            panel.setFrame(NSRect(x: area.midX - panelWidth / 2, y: top + model.headerHeight - model.height,
                                  width: panelWidth, height: model.height), display: false)
        }
        content.layoutSubtreeIfNeeded()
        if let field = findTextField(in: content) { panel.makeFirstResponder(field) }
        waitingForStartupInput = reply.clipboardMode != true
        reportedStartupReady = false
        lastPointerLocation = NSEvent.mouseLocation
        pointerTimer?.fireDate = .now
        panel.orderFrontRegardless()
        panel.makeKey()
        reportStartupReadyIfKey()
    }

    private var hidingResidentPanel = false

    private func hideResidentPanel() {
        guard let panel, !hidingResidentPanel else { return }
        hidingResidentPanel = true
        if searchContent != nil { dismissLargeType() }
        let preview = activePreview
        activePreview = nil
        panel.previewURL = nil
        preview?.close()
        panel.orderOut(nil)
        waitingForStartupInput = false
        startupEvents.removeAll()
        pointerTimer?.fireDate = .distantFuture
        hidingResidentPanel = false
        model.reportPanelHidden()
    }

    func windowDidResignKey(_ notification: Notification) {
        guard activePreview == nil else { return }
        if resident {
            if panel?.isVisible == true { hideResidentPanel() }
        } else {
            NSApp.terminate(nil)
        }
    }

    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        guard let event else { return false }
        return closePreviewOnEscape(event)
    }

    private func closePreviewOnEscape(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown, event.keyCode == 53, activePreview != nil else { return false }
        if !event.isARepeat { closeActivePreview() }
        return true
    }

    private func closeActivePreview() {
        guard let preview = activePreview else { return }
        preview.close()
        restoreAfterPreview(preview)
    }

    func windowWillClose(_ notification: Notification) {
        if let preview = notification.object as? QLPreviewPanel, preview === activePreview {
            restoreAfterPreview(preview)
        }
    }

    private func restoreAfterPreview(_ preview: QLPreviewPanel) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.activePreview === preview, let panel = self.panel else { return }
            panel.makeKeyAndOrderFront(nil)
            panel.previewURL = nil
            self.activePreview = nil
            self.model.reportPreview(open: false)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        pointerTimer?.invalidate()
    }

    private func installEditMenu() {
        let mainMenu = NSMenu()
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        for (title, action, key) in [
            ("Cut", #selector(NSText.cut(_:)), "x"),
            ("Copy", #selector(NSText.copy(_:)), "c"),
            ("Paste", #selector(NSText.paste(_:)), "v"),
            ("Select All", #selector(NSText.selectAll(_:)), "a"),
        ] {
            editMenu.addItem(withTitle: title, action: action, keyEquivalent: key)
        }
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)
        NSApp.mainMenu = mainMenu
    }

    private func findTextField(in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField { return field }
        return view.subviews.lazy.compactMap { self.findTextField(in: $0) }.first
    }
}

@main
private enum Main {
    @MainActor private static func readCopiedSelection() {
        let board = NSPasteboard.general
        let originalCount = board.changeCount
        var saved: [NSPasteboardItem] = []
        for item in board.pasteboardItems ?? [] {
            let copy = NSPasteboardItem()
            for type in item.types {
                guard let data = item.data(forType: type), copy.setData(data, forType: type) else { return }
            }
            saved.append(copy)
        }
        guard board.changeCount == originalCount else { return }
        FileHandle.standardOutput.write(Data("ready \(originalCount)\n".utf8))
        guard readLine() == "copy" else { return }

        let deadline = ProcessInfo.processInfo.systemUptime + 0.55
        while board.changeCount == originalCount {
            guard ProcessInfo.processInfo.systemUptime < deadline else { return }
            Thread.sleep(forTimeInterval: 0.015)
        }
        let selectionCount = board.changeCount
        let result: [String: String]
        if let value = board.string(forType: .fileURL),
           let file = URL(string: value), file.isFileURL {
            result = ["path": file.path]
        } else {
            result = ["text": board.string(forType: .string) ?? ""]
        }
        guard board.changeCount == selectionCount else { return }
        board.clearContents()
        if !saved.isEmpty, !board.writeObjects(saved) { return }
        if let payload = try? JSONEncoder().encode(result) {
            FileHandle.standardOutput.write(payload)
        }
    }

    private struct StorageVolume: Encodable {
        let name: String
        let mountPath: String
        let total: Int64
        let used: Int64
        let external: Bool
    }

    private static func reportStorage() throws {
        let keys: Set<URLResourceKey> = [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey,
            .volumeIsInternalKey, .volumeIsLocalKey,
        ]
        let root = URL(fileURLWithPath: "/", isDirectory: true)
        let mounts = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeIsInternalKey, .volumeIsLocalKey],
            options: [.skipHiddenVolumes]
        ) ?? []
        let session = DASessionCreate(kCFAllocatorDefault)
        let volumes = ([root] + mounts.filter { $0.path != "/" }).compactMap { url -> StorageVolume? in
            let external = url.path != "/"
            if external {
                guard let flags = try? url.resourceValues(forKeys: [.volumeIsInternalKey, .volumeIsLocalKey]),
                      flags.volumeIsLocal == true, flags.volumeIsInternal == false else { return nil }
                if let session, let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL),
                   let description = DADiskCopyDescription(disk) as? [String: Any],
                   let transport = description[kDADiskDescriptionDeviceProtocolKey as String] as? String,
                   transport.localizedCaseInsensitiveContains("disk image") || transport.lowercased() == "virtual" {
                    return nil
                }
            }
            guard let values = try? url.resourceValues(forKeys: keys),
                  let total = values.volumeTotalCapacity, total > 0,
                  let available = values.volumeAvailableCapacity else { return nil }
            return StorageVolume(name: values.volumeName ?? url.lastPathComponent,
                                 mountPath: url.path,
                                 total: Int64(total), used: Int64(total - min(total, max(0, available))),
                                 external: external)
        }.sorted {
            if $0.external != $1.external { return !$0.external }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        try FileHandle.standardOutput.write(contentsOf: JSONEncoder().encode(volumes))
    }

    private static func encodeClipboardImage(to path: String) -> Bool {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard data.count <= 96 * 1024 * 1024,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let attributes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = attributes[kCGImagePropertyPixelWidth] as? Int,
              let height = attributes[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= 16_000_000 / height else { return false }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(width, height),
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return false }
        let png = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(png, "public.png" as CFString, 1, nil) else { return false }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination), png.length <= 16 * 1024 * 1024 else { return false }
        do {
            try (png as Data).write(to: URL(fileURLWithPath: path), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    @MainActor static func main() {
        let args = CommandLine.arguments
        if args.count == 3, args[1] == "--encode-clipboard-image" {
            exit(encodeClipboardImage(to: args[2]) ? 0 : 1)
        }
        if args.count == 2, args[1] == "--storage-volumes" {
            do { try reportStorage() } catch { exit(1) }
            return
        }
        if args.count == 2, args[1] == "--read-copied-selection" {
            readCopiedSelection()
            return
        }
        let app = NSApplication.shared
        let launcher = Launcher()
        app.setActivationPolicy(.accessory)
        app.delegate = launcher
        app.run()
    }
}
