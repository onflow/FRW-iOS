//
//  PresentHostingController.swift
//  FRW
//
//  Created by cat on 2024/6/13.
//

import SwiftUI

// MARK: - Present Action

typealias PresentActionView = PresentActionDelegate & View

// MARK: - PresentActionDelegate

protocol PresentActionDelegate {
    func customViewDidDismiss()
    var detents: [UISheetPresentationController.Detent] { get }
    var prefersGrabberVisible: Bool { get }

    var changeHeight: (() -> Void)? { get set }
}

extension PresentActionDelegate {
    var detents: [UISheetPresentationController.Detent] {
        [.medium()]
    }

    var prefersGrabberVisible: Bool {
        true
    }

    func customViewDidDismiss() {}
}

// MARK: - PresentHostingController

final class PresentHostingController<Content: PresentActionView>: UIHostingController<Content>,
    UISheetPresentationControllerDelegate
{
    // MARK: Lifecycle

    public init(backgroundColor _: Color = Color.Summer.sheet, rootView: Content) {
        super.init(rootView: rootView)
        overrideUserInterfaceStyle = ThemeManager.shared.getUIKitStyle()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()

        // setting presentation controller properties...
        if let presentationController = presentationController as? UISheetPresentationController {
            presentationController.detents = rootView.detents
            presentationController.prefersGrabberVisible = rootView.prefersGrabberVisible
            presentationController.delegate = self
        }
        rootView.changeHeight = {
            self.changeHeight()
        }
    }

    func changeHeight() {
        guard let sheet = presentationController as? UISheetPresentationController else {
            return
        }
        let oldValue = sheet.selectedDetentIdentifier ?? .medium

        sheet.animateChanges {
            sheet.selectedDetentIdentifier = oldValue.oppositeValue
        }
    }

    @objc
    func presentationControllerDidDismiss(_: UIPresentationController) {
        rootView.customViewDidDismiss()
    }
}

extension UISheetPresentationController.Detent.Identifier {
    var oppositeValue: UISheetPresentationController.Detent.Identifier {
        switch self {
        case .medium:
            return .large
        case .large:
            return .medium
        default:
            fatalError("Unsupported value")
        }
    }
}
