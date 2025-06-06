//
//  SegmentedControl.swift
//  FRW
//
//  Created by cat on 6/6/25.
//

import SwiftUI

// MARK: - Tab ImageSource

public enum ImageSource: Hashable {
    case system(name: String)
    case asset(name: String)
}

public enum SegmentedTabItem: Hashable, Identifiable {
    case text(String)
    case image(ImageSource)
    case imageWithText(ImageSource, String)
    public var id: String {
        switch self {
        case let .text(text):
            return "text_\(text)"
        case let .image(source):
            return "image_\(source)"
        case let .imageWithText(source, text):
            return "imageWithText_\(source)_\(text)"
        }
    }
}

// MARK: - SegmentedIndicator

public protocol SegmentedIndicator: View {
    init(color: Color, size: CGSize)
}

// MARK: - UnderlineIndicator

public struct UnderlineIndicator: SegmentedIndicator {
    let color: Color
    let size: CGSize
    public init(color: Color, size: CGSize) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(height: 4)
            .padding(.horizontal, 10)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

// MARK: - CapsuleIndicator

public struct CapsuleIndicator: SegmentedIndicator {
    let color: Color
    let size: CGSize
    public init(color: Color, size: CGSize) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: size.height / 2)
            .fill(color)
            .frame(maxHeight: .infinity)
            .padding(3)
    }
}

// MARK: - SegmentedControl

public struct SegmentedControl<Indicator: View>: View {
    public var tabs: [SegmentedTabItem]
    @Binding public var selectedIndex: Int
    public var height: CGFloat = 45
    public var font: Font = .title3
    public var activeTint: Color
    public var inActiveTint: Color
    @ViewBuilder public var indicatorViewBuilder: (CGSize) -> Indicator

    @State private var excessTabWidth: CGFloat = .zero
    @State private var minX: CGFloat = .zero

    public init(
        tabs: [SegmentedTabItem],
        selectedIndex: Binding<Int>,
        height: CGFloat = 45,
        font: Font = .title3,
        activeTint: Color,
        inActiveTint: Color,
        @ViewBuilder indicatorViewBuilder: @escaping (CGSize) -> Indicator
    ) {
        self.tabs = tabs
        _selectedIndex = selectedIndex
        self.height = height
        self.font = font
        self.activeTint = activeTint
        self.inActiveTint = inActiveTint
        self.indicatorViewBuilder = indicatorViewBuilder
    }

    public var body: some View {
        if tabs.isEmpty {
            EmptyView()
        } else {
            GeometryReader { proxy in
                let size = proxy.size
                let containerWidthForEachTab = size.width / CGFloat(tabs.count)
                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \ .1.id) { index, tab in
                        Group {
                            switch tab {
                            case let .text(text):
                                Text(text)
                            case let .image(source):
                                SegmentedTabImageView(source: source)
                            case let .imageWithText(source, text):
                                HStack(spacing: 4) {
                                    SegmentedTabImageView(source: source)
                                    Text(text)
                                }
                            }
                        }
                        .font(font)
                        .foregroundStyle(selectedIndex == index ? activeTint : inActiveTint)
                        .animation(.snappy, value: selectedIndex)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(.rect)
                        .onTapGesture {
                            if index != selectedIndex && index >= 0 && index < tabs.count {
                                let oldIndex = selectedIndex
                                selectedIndex = index
                                #if os(iOS)
                                    if #available(iOS 17.0, *) {
                                        withAnimation(
                                            .snappy(duration: 0.25, extraBounce: 0),
                                            completionCriteria: .logicallyComplete
                                        ) {
                                            excessTabWidth = containerWidthForEachTab * CGFloat(index - oldIndex)
                                        } completion: {
                                            withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                                                minX = containerWidthForEachTab * CGFloat(index)
                                                excessTabWidth = 0
                                            }
                                        }
                                    } else {
                                        minX = containerWidthForEachTab * CGFloat(index)
                                        excessTabWidth = 0
                                    }
                                #else
                                    minX = containerWidthForEachTab * CGFloat(index)
                                    excessTabWidth = 0
                                #endif
                            }
                        }
                        .background(alignment: .leading) {
                            if index == 0 {
                                GeometryReader { geo in
                                    let tabSize = geo.size
                                    Group {
                                        indicatorViewBuilder(tabSize)
                                    }
                                    .frame(
                                        width: tabSize.width + abs(excessTabWidth),
                                        height: tabSize.height
                                    )
                                    .frame(
                                        width: tabSize.width,
                                        alignment: excessTabWidth < 0 ? .trailing : .leading
                                    )
                                    .offset(x: minX)
                                }
                            }
                        }
                    }
                }
                .preference(key: SizeKey.self, value: size)
                .onPreferenceChange(SizeKey.self) { _ in
                    if selectedIndex >= 0 && selectedIndex < tabs.count {
                        minX = containerWidthForEachTab * CGFloat(selectedIndex)
                        excessTabWidth = 0
                    }
                }
            }
            .frame(height: height)
            .onAppear {
                correctSelectedIndexIfNeeded()
            }
            .onChange(of: tabs) { _ in
                correctSelectedIndexIfNeeded()
            }
            .onChange(of: selectedIndex) { _ in
                correctSelectedIndexIfNeeded()
            }
        }
    }

    private func correctSelectedIndexIfNeeded() {
        guard !tabs.isEmpty else { return }
        if selectedIndex < 0 {
            selectedIndex = 0
        } else if selectedIndex >= tabs.count {
            selectedIndex = tabs.count - 1
        }
    }
}

// MARK: - SizeKey

private struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - SegmentedTabImageView

struct SegmentedTabImageView: View {
    let source: ImageSource
    var body: some View {
        switch source {
        case let .system(name):
            Image(systemName: name)
        case let .asset(name):
            Image(name)
        }
    }
}
