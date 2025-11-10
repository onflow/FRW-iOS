//
//  AdaptiveHostingController.swift
//  FRW
//
//  Created by cat on 2024/11/03.
//

import SwiftUI

// MARK: - AdaptiveHostingController

/// A hosting controller that automatically adapts its size to the content
final class AdaptiveHostingController<Content: View>: UIHostingController<AdaptiveContentWrapper<Content>> {

    // MARK: Properties

    private var currentContentHeight: CGFloat = 400

    // MARK: Lifecycle

    init(rootView: Content, maxWidth: CGFloat = UIScreen.main.bounds.width) {
        let wrapper = AdaptiveContentWrapper(content: rootView, maxWidth: maxWidth)
        super.init(rootView: wrapper)

        // Set initial presentation style
        modalPresentationStyle = .pageSheet

        // Apply current theme
        overrideUserInterfaceStyle = ThemeManager.shared.getUIKitStyle()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Brand.Core.cards
        // Configure sheet presentation
        if let sheetController = presentationController as? UISheetPresentationController {
            // Use a custom detent that adapts to content
            let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("adaptive")) { [weak self] context in
                return self?.calculateOptimalHeight(in: context) ?? 400
            }

            sheetController.detents = [customDetent]
            sheetController.prefersGrabberVisible = true
            sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
            sheetController.preferredCornerRadius = 16
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update sheet size after layout
        DispatchQueue.main.async { [weak self] in
            self?.updateSheetSize()
        }
    }

    // MARK: Public Methods

    func updateContentHeight(_ height: CGFloat) {
        currentContentHeight = height
        updateSheetSize()
    }

    // MARK: Private Methods

    private func calculateOptimalHeight(in context: UISheetPresentationControllerDetentResolutionContext) -> CGFloat {
        // Calculate the content's size
        let targetSize = view.systemLayoutSizeFitting(
            CGSize(width: context.maximumDetentValue, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Use the calculated height with some padding
        let contentHeight = targetSize.height

        // Ensure reasonable bounds
        let minHeight: CGFloat = 200
        let maxHeight = context.maximumDetentValue * 0.9

        return min(max(contentHeight, minHeight), maxHeight)
    }

    private func updateSheetSize() {
        guard let sheetController = presentationController as? UISheetPresentationController else { return }

        // Invalidate detents to trigger recalculation
        sheetController.animateChanges {
            sheetController.invalidateDetents()
        }
    }
}

// MARK: - AdaptiveContentWrapper

struct AdaptiveContentWrapper<Content: View>: View {
    let content: Content
    let maxWidth: CGFloat
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        content
            .frame(maxWidth: maxWidth)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            contentHeight = geometry.size.height
                        }
                        .onChange(of: geometry.size) { newSize in
                            contentHeight = newSize.height
                        }
                }
            )
    }
}
