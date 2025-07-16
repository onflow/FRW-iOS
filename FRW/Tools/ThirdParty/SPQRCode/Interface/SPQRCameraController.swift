// The MIT License (MIT)
// Copyright © 2022 Sparrow Code (hello@sparrowcode.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import AVKit
import SnapKit
import SwiftUI
import UIKit

public typealias SPQRCodeCallback = (SPQRCodeData, SPQRCameraController) -> Void

// MARK: - SPQRCameraController

open class SPQRCameraController: SPController {
    // MARK: Lifecycle

    override public init() {
        super.init()
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Open

    open var detectQRCodeData: ((SPQRCodeData, SPQRCameraController) -> SPQRCodeData?) =
        { data, _ in
            data
        }

    open var handledQRCodeData: SPQRCodeCallback?
    open var clickQRCodeData: SPQRCodeCallback?

    override open var prefersStatusBarHidden: Bool {
        true
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        view.layoutMargins = .init(horizontal: 20, vertical: .zero)
        view.layer.addSublayer(previewLayer)
        view.layer.addSublayer(frameLayer)
        captureSession.startRunning()

        maskView.statusBarHeight = statusBarHeight
        view.addSubviews(maskView)

        detailView.addTarget(self, action: #selector(didTapDetailButtonClick), for: .touchUpInside)
        view.addSubview(detailView)

        addBackButton()
        updateInterface()
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        previewLayer.frame = .init(
            x: .zero, y: .zero,
            width: view.layer.bounds.width,
            height: view.layer.bounds.height
        )
        maskView.frame = previewLayer.frame
    }

    // MARK: Internal

    static let supportedCodeTypes = [
        AVMetadataObject.ObjectType.aztec,
        AVMetadataObject.ObjectType.qr,
    ]

    var updateTimer: Timer?
    lazy var captureSession: AVCaptureSession = makeCaptureSession()

    // MARK: - Views

    let frameLayer = SPQRFrameLayer()
    let detailView = SPQRDetailButton()
    lazy var previewLayer = makeVideoPreviewLayer()
    let maskView = SPQRMaskView()

    var qrCodeData: SPQRCodeData? {
        didSet {
            updateInterface()
            didTapHandledButton()
        }
    }

    func stopRunning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    // MARK: - Actions

    @objc
    func didTapHandledButton() {
        guard let data = qrCodeData else { return }
        handledQRCodeData?(data, self)
    }

    @objc
    func didTapCancelButton() {
        dismissAnimated()
    }

    func updateInterface() {
        let duration: TimeInterval = 0.22
        if qrCodeData != nil {
            detailView.isHidden = false
            if case .flowWallet = qrCodeData {
                detailView.applyDefaultAppearance(with: .init(
                    content: .white,
                    background: UIColor(hex: "#00EF8B")
                ))
                frameLayer.strokeColor = UIColor(hex: "#00EF8B").cgColor
            }
            if case .ethWallet = qrCodeData {
                detailView.applyDefaultAppearance(with: .init(
                    content: .white,
                    background: UIColor(hex: "#00EF8B")
                ))
                frameLayer.strokeColor = UIColor(hex: "#00EF8B").cgColor
            }
            UIView.animate(
                withDuration: duration,
                delay: .zero,
                options: .curveEaseInOut,
                animations: {
                    self.detailView.transform = .identity
                    self.detailView.alpha = 1
                }
            )
        } else {
            UIView.animate(
                withDuration: duration,
                delay: .zero,
                options: .curveEaseInOut,
                animations: {
                    self.detailView.transform = .init(scale: 0.9)
                    self.detailView.alpha = .zero
                },
                completion: { _ in
                    self.detailView.isHidden = true
                }
            )
        }
    }

    func makeVideoPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        return videoPreviewLayer
    }

    func makeCaptureSession() -> AVCaptureSession {
        let captureSession = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { fatalError() }
        guard let input = try? AVCaptureDeviceInput(device: device) else { fatalError() }
        captureSession.addInput(input)
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = Self.supportedCodeTypes
        return captureSession
    }

    // MARK: Private

    @objc
    private func didTapDetailButtonClick() {
        guard let data = qrCodeData else { return }
        clickQRCodeData?(data, self)
    }

    // MARK: - Layout

    private func addBackButton() {
        let image = UIImage(systemName: "arrow.backward")
        let backButton = UIButton(type: .custom)
        backButton.setImage(image, for: .normal)
        backButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        backButton.tintColor = .white
        backButton.sizeToFit()
        view.addSubview(backButton)

        backButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.left.equalTo(0)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }

        let titleLabel = UILabel()
        titleLabel.text = "scan_qr_title".localized
        titleLabel.textColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)
        titleLabel.font = UIFont.interSemiBold(size: 18)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(64)
            make.right.equalTo(-64)
            make.centerY.equalTo(backButton.snp.centerY)
        }
    }
}

extension UIViewController {
    var statusBarHeight: CGFloat {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let height = scene.statusBarManager?.statusBarFrame.height
        else {
            return 0
        }
        return height
    }
}
