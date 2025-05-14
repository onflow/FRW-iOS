//
//  ManualBackupView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 4/1/22.
//

import SwiftUI

// MARK: - EnumeratedForEach

struct EnumeratedForEach<ItemType, ContentView: View>: View {
    // MARK: Lifecycle

    init(_ data: [ItemType], @ViewBuilder content: @escaping (Int, ItemType) -> ContentView) {
        self.data = data
        self.content = content
    }

    // MARK: Internal

    let data: [ItemType]
    let content: (Int, ItemType) -> ContentView

    var body: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { idx, item in
            self.content(idx, item)
        }
    }
}

extension ManualBackupView {
    enum ViewState {
        case initScreen
        case render(dataSource: [BackupModel])
    }

    enum Action {
        case loadDataSource
        case backupSuccess
    }
}

// MARK: - ManualBackupView

struct ManualBackupView: RouteableView {
    struct BackupModel: Identifiable {
        let id = UUID()
        let position: Int
        let correct: Int
        let list: [String]
    }

    @StateObject
    var viewModel = ManualBackupViewModel()

    @State
    var selectArray: [Int?] = [nil, nil, nil, nil]

    var model: VSegmentedPickerModel = {
        var model = VSegmentedPickerModel()
        model.colors.background = .init(
            enabled: .LL.bgForIcon,
            disabled: .LL.bgForIcon
        )

        model.fonts.rows = .LL.body.weight(.semibold)
        model.layout.height = 64
        model.layout.cornerRadius = 16
        model.layout.indicatorCornerRadius = 16
        model.layout.indicatorMargin = 8
        model.layout.headerFooterSpacing = 8
        return model
    }()

    var title: String {
        ""
    }

    var isAllPass: Bool {
        if case let .render(dataSource) = viewModel.state {
            return dataSource.map { $0.correct } == selectArray
        }
        return false
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("double".localized)
                            .bold()
                            .foregroundColor(Color.LL.text)

                        Text("secure".localized)
                            .bold()
                            .foregroundColor(Color.LL.orange)
                    }
                    .font(.LL.largeTitle)

                    Text("select_word_by_order".localized)
                        .font(.LL.body)
                        .foregroundColor(.LL.note)
                        .padding(.top, 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 30)

                if case let .render(dataSource) = viewModel.state {
                    EnumeratedForEach(dataSource) { index, element in

                        VStack(alignment: .leading) {
                            HStack {
                                Text("select_the_word".localized)
                                Text("#\(element.position)")
                                    .fontWeight(.semibold)
                            }
                            .font(.LL.body)

                            VSegmentedPicker(
                                model: model,
                                selectedIndex: $selectArray[index],
                                data: element.list
                            ) { item in
                                VText(
                                    type: .oneLine,
                                    font: model.fonts.rows,
                                    color: getColor(
                                        selectIndex: selectArray[index],
                                        item: item,
                                        list: element.list,
                                        currentListIndex: index,
                                        correct: element.correct
                                    ),
                                    title: item
                                )
                            }
                        }
                        .padding(.bottom)
                    }
                }

                VPrimaryButton(
                    model: ButtonStyle.primary,
                    state: isAllPass ? .enabled : .disabled,
                    action: {
                        viewModel.trigger(.backupSuccess)
                    },
                    title: "Next"
                )
                .padding(.top, 20)
                .padding(.bottom)
            }
        }
        .padding(.horizontal, 28)
        .background(Color.LL.background, ignoresSafeAreaEdges: .all)
        .onAppear {
            viewModel.trigger(.loadDataSource)
        }
        .applyRouteable(self)
        .tracedView(self)
    }

    func getColor(
        selectIndex: Int?,
        item: String,
        list: [String],
        currentListIndex _: Int,
        correct: Int
    ) -> Color {
        guard let selectIndex = selectIndex else {
            return .LL.text
        }

        guard let index = list.firstIndex(of: item), selectIndex == index else {
            return .LL.text
        }

        return selectIndex == correct ? Color.LL.success : Color.LL.error
    }
}

// MARK: - ManualBackupView_Previews

struct ManualBackupView_Previews: PreviewProvider {
    static var previews: some View {
        ManualBackupView()
    }
}
