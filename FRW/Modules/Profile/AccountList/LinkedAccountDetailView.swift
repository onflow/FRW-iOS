//
//  LinkedAccountDetailView.swift
//  FRW
//
//  Created by cat on 11/19/25.
//

import Kingfisher
import SwiftUI
import SwiftUIX

// MARK: - LinkedAccountDetailView

struct LinkedAccountDetailView: View {
    // MARK: Lifecycle

    init(account: Binding<WalletAccount>) {
        self._account = account
        self._vm = StateObject(wrappedValue: LinkedAccountDetailViewModel(account: account))
    }

    // MARK: Internal

    @Binding var account: WalletAccount
    @StateObject var vm: LinkedAccountDetailViewModel

    private let radius: CGFloat = 16

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 36) {
                    // Account Info Section
                    VStack(spacing: 10) {
                        AccountHeaderView(account: $account)
                            .cornerRadius(radius)

                        AccountAddressView(account: account)
                            .cornerRadius(radius)
                    }

                    // Accessible Assets Section
                    accessibleAssetsSection
                }
            }
            .scrollIndicators(.never)
        }
    }

    // MARK: Private

    private var accessibleAssetsSection: some View {
        VStack(spacing: 18) {
            // Header with toggle
            accessibleAssetsHeader

            // Segment Control (Collections/Coins)
            segmentControl

            // Collection List
            collectionListView
        }
    }

    private var accessibleAssetsHeader: some View {
        HStack {
            Text("accessible_cap".localized)
                .font(.inter(size: 16, weight: .medium))
                .foregroundStyle(Color.Brain.Text.primary)

            Spacer()

            HStack(spacing: 8) {
                Text("view_empty".localized)
                    .font(.inter(size: 12))
                    .foregroundStyle(Color.Brain.Text.secondary)

                Toggle(isOn: $vm.showEmptyCollection) {}
                    .tint(Color(hex: "#30D158"))
                    .labelsHidden()
                    .onChange(of: vm.showEmptyCollection) { _ in
                        vm.switchEmptyCollection()
                    }
                    .padding(.trailing, 2)
            }
        }
        .padding(.top, 16)
        .overlay(alignment: .top) {
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }

    private var segmentControl: some View {
        LinkedAccountSegmentControl(
            selectedIndex: $vm.tabIndex,
            titles: ["collections".localized, "coins_cap".localized]
        ) { index in
            vm.switchTab(index: index)
        }
    }

    private var collectionListView: some View {
        VStack(spacing: 0) {
            if vm.accessibleItems.isEmpty && !vm.isLoading {
                emptyAccessibleView
            } else {
                ForEach(Array(vm.accessibleItems.enumerated()), id: \.element.id) { index, item in
                    AccessibleCollectionRow(
                        item: item,
                        isLast: index == vm.accessibleItems.count - 1
                    ) {
                        vm.onCollectionClick(item)
                    }
                }
            }
        }
        .background(Color.Brain.Core.cards)
        .cornerRadius(radius)
        .mockPlaceholder(vm.isLoading)
    }

    private var emptyAccessibleView: some View {
        HStack {
            Text(vm.accessibleEmptyTitle)
                .font(.inter(size: 14, weight: .semibold))
                .foregroundStyle(Color.Brain.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .padding(.horizontal, 18)
    }
}

// MARK: - LinkedAccountSegmentControl

struct LinkedAccountSegmentControl: View {
    @Binding var selectedIndex: Int
    let titles: [String]
    var onSelect: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(titles.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = index
                    }
                    onSelect?(index)
                } label: {
                    Text(titles[index])
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundStyle(textColor(for: index))
                        .frame(maxWidth: .infinity)
                        .frame(height: 33)
                        .background(backgroundColor(for: index))
                        .cornerRadius(24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 200)
                .stroke(Color.Brain.Core.container, lineWidth: 2)
        )
        .frame(height: 43)
    }

    private func textColor(for index: Int) -> Color {
        selectedIndex == index ? Color.Brain.Text.primary : Color.Brain.Text.secondary
    }

    private func backgroundColor(for index: Int) -> Color {
        selectedIndex == index ? Color.Brain.Core.container : Color.clear
    }
}

// MARK: - AccessibleCollectionRow

struct AccessibleCollectionRow: View {
    let item: ChildAccountAccessible
    let isLast: Bool
    var onClick: (() -> Void)?

    var body: some View {
        Button {
            onClick?()
        } label: {
            HStack(spacing: 14) {
                // Collection Icon
              Color.random()
                .frame(width: 36, height: 36)
                .cornerRadius(18)

                // Collection Name
                Text(item.title)
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Brain.Text.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Count (if available)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Brain.Text.secondary)
                }

                // Arrow
                if item.isShowNext {
                    Image("icon-black-right-arrow")
                        .renderingMode(.template)
                        .foregroundColor(Color.Brain.Text.primary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast {
                    Divider()
                        .background(Color.Brain.Core.dividers)
                        .padding(.horizontal, 18)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var account = WalletAccount.mockChild()

        var body: some View {
            LinkedAccountDetailView(account: $account)
                .background(Color.Brain.Core.background)
        }
    }

    return PreviewWrapper()
}
