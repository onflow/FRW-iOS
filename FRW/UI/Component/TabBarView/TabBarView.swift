//
//  TabBarView.swift
//  Test
//
//  Created by cat on 2022/5/23.
//

import SwiftUI

// MARK: - TabBarView

struct TabBarView<T: Hashable>: View {
    // MARK: Lifecycle

    init(current: T, pages: [TabBarPageModel<T>], maxWidth: CGFloat) {
        _current = State(initialValue: current)
        self.pages = pages
        self.maxWidth = maxWidth

        var selectIndex = 0
        for (index, page) in pages.enumerated() {
            if page.tag == current {
                selectIndex = index
            }
        }
        _currentIndex = State(initialValue: selectIndex)
        _offsetX = State(initialValue: maxWidth * CGFloat(selectIndex))
    }

    // MARK: Internal

    @State
    var current: T
    var pages: [TabBarPageModel<T>]

    var maxWidth: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            tabView
            TabBar(
                pages: pages,
                indicatorColor: getCurrentPageModel() != nil ? Color.Theme.Accent.green : .clear,
                offsetX: $offsetX,
                selected: $current
            )
        }
    }

    var tabView: some View {
        TabView(selection: $current) {
            ForEach(0..<pages.count, id: \.self) { index in
                let pageModel = pages[index]
                pageModel.view()
                    .tag(pageModel.tag)
                    .background(
                        GeometryReader {
                            Color.clear.preference(
                                key: ViewOffsetKey.self,
                                value: $0.frame(in: .named("frameLayer"))
                            )
                        }
                    )
                    .onPreferenceChange(ViewOffsetKey.self) {
                        offset(index: index, frame: $0)
                    }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .background(Color(uiColor: UIColor.LL.Neutrals.background))
        .ignoresSafeArea()
        .animation(.none, value: current)
        .onChange(of: current) { _ in
            debugPrint("tab onChange \(current)")
            currentIndex = getCurrentPageIndex()
        }
        .coordinateSpace(name: "frameLayer")
    }

    // MARK: Private

    @State
    private var offsetX: CGFloat
    @State
    private var currentIndex: Int

    private func offset(index: Int, frame: CGRect) {
        if currentIndex == index {
            let x = -frame.origin.x
            offsetX = CGFloat(index) * frame.size.width + x
        }
    }

    private func getCurrentPageModel() -> TabBarPageModel<T>? {
        pages.first { $0.tag == current }
    }

    private func getCurrentPageIndex() -> Int {
        pages.firstIndex { $0.tag == current } ?? 0
    }
}

// MARK: - ViewOffsetKey

private struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGRect

    static var defaultValue = CGRect.zero

    static func reduce(value _: inout Value, nextValue _: () -> Value) {}
}
