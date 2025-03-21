//
//  TabBar.swift
//  Test
//
//  Created by Selina on 27/5/2022.
//

import SwiftUI

// MARK: - TabBarView.TabBar

extension TabBarView {
    struct TabBar<T: Hashable>: View {
        // MARK: Internal

        var pages: [TabBarPageModel<T>]
        var indicatorColor: Color
        @Binding
        var offsetX: CGFloat
        @Binding
        var selected: T

        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            let pm = pages[index]
                            TabBarItemView(pageModel: pm, selected: $selected) {
                                if pm.tag != selected {
                                    resetOffset(index: index, maxWidth: proxy.size.width)
                                }
                            }
                        }
                    }
                    .background(.LL.deepBg)

                    indicator(proxy.size.width).animation(.spring(), value: offsetX)
                }
            }
            .frame(height: 46)
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }

        // MARK: Private

        private let indicatorWidth: CGFloat = 65

        @ViewBuilder
        private func indicator(_ parentMaxWidth: CGFloat) -> some View {
            let pageCount = CGFloat(pages.count)
            let scrollMaxOffsetX = (parentMaxWidth + 32) * (pageCount - 1)
            let scrollPercent = max(0, min(1, offsetX / scrollMaxOffsetX))
            let perBarItemWidth = parentMaxWidth / pageCount
            let startX = perBarItemWidth / 2.0 - indicatorWidth / 2.0
            let endX = perBarItemWidth * (pageCount - 1) + startX
            let translateX = (endX - startX) * scrollPercent + startX

            Rectangle()
                .frame(width: indicatorWidth, height: 2)
                .foregroundColor(indicatorColor)
                .modifier(TranslateEffect(offsetX: translateX))
                .animation(.tabSelect, value: offsetX)
        }

        private func resetOffset(index: Int, maxWidth: CGFloat) {
            offsetX = CGFloat(index) * maxWidth
        }
    }
}

// MARK: - TranslateEffect

private struct TranslateEffect: GeometryEffect {
    var offsetX: CGFloat

    var animatableData: CGFloat {
        get { offsetX }
        set { offsetX = newValue }
    }

    func effectValue(size _: CGSize) -> ProjectionTransform {
        ProjectionTransform(.init(translationX: offsetX, y: 0))
    }
}

extension Animation {
    fileprivate static let tabSelect = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
