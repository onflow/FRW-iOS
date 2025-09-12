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
        
        // Set up UI elements on main thread
        previewLayer.videoGravity = .resizeAspectFill
        
        // Fix layer order: ensure previewLayer is visible but below maskView
        view.layer.addSublayer(previewLayer)
        
        maskView.statusBarHeight = statusBarHeight
        view.addSubviews(maskView)
        
        // Ensure frameLayer is on top for QR code highlighting
        view.layer.addSublayer(frameLayer)

        detailView.addTarget(self, action: #selector(didTapDetailButtonClick), for: .touchUpInside)
        view.addSubview(detailView)

        addBackButton()
        updateInterface()
        
        // Configure camera session on dedicated background queue
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // UI updates on main thread
        previewLayer.frame = view.bounds
        maskView.frame = view.bounds
    }

    // MARK: Internal

    static let supportedCodeTypes = [
        AVMetadataObject.ObjectType.aztec,
        AVMetadataObject.ObjectType.qr,
    ]

    var updateTimer: Timer?
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.frw.camera.session.queue")

    // MARK: - Views

    let frameLayer = SPQRFrameLayer()
    let detailView = SPQRDetailButton()
    lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    let maskView = SPQRMaskView()

    var qrCodeData: SPQRCodeData? {
        didSet {
            updateInterface()
            didTapHandledButton()
        }
    }

    func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
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


    private func configureSession() {
        // Check camera permissions first
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Permission granted, continue with session configuration
            break
        case .notDetermined:
            // Request permission first
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    // Permission granted, retry configuration
                    self?.configureSession()
                } else {
                    // Permission denied, show alert
                    DispatchQueue.main.async {
                        self?.handleCameraPermissionDenied()
                    }
                }
            }
            return
        case .denied, .restricted:
            // Permission denied or restricted, show alert
            DispatchQueue.main.async { [weak self] in
                self?.handleCameraPermissionDenied()
            }
            return
        @unknown default:
            // Handle future cases
            DispatchQueue.main.async { [weak self] in
                self?.handleCameraPermissionDenied()
            }
            return
        }
        
        // If session is already configured and running, just restart it
        if captureSession.isRunning {
            return
        }
        
        // Check if session is already configured (has inputs)
        if !captureSession.inputs.isEmpty {
            // Session was previously configured, just restart it
            captureSession.startRunning()
            return
        }
        
        // First time configuration
        captureSession.beginConfiguration()
        
        // Configure video input
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("Failed to get camera device")
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Failed to create camera input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        // Configure metadata output for QR code detection
        let captureMetadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(captureMetadataOutput) {
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = Self.supportedCodeTypes
        }
        
        captureSession.commitConfiguration()
        
        // Start running the session
        captureSession.startRunning()
        
        // Debug logging to help diagnose camera issues
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("🔍 Camera Debug - Session started: \(self.captureSession.isRunning)")
            print("🔍 Camera Debug - Preview layer frame: \(self.previewLayer.frame)")
            print("🔍 Camera Debug - View bounds: \(self.view.bounds)")
        }
    }
    
    private func handleCameraPermissionDenied() {
        let title = "camera_permission_required_title".localized
        let message = "camera_permission_required_message".localized
        let settingsButtonTitle = "settings".localized
        let cancelButtonTitle = "cancel".localized
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Settings button - opens app settings
        let settingsAction = UIAlertAction(title: settingsButtonTitle, style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        
        // Cancel button - dismisses the scanner
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { [weak self] _ in
            self?.dismissAnimated()
        }
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
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
