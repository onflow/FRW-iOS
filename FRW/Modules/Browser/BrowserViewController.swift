//
//  BrowserViewController.swift
//  Flow Wallet
//
//  Created by Selina on 1/9/2022.
//

import Combine
import Hero
import SnapKit
import SwiftUI
import TrustWeb3Provider
import UIKit
import WebKit

// MARK: - BrowserViewController

class BrowserViewController: UIViewController {
    // MARK: Lifecycle

    deinit {
        observation = nil
    }

    // MARK: Public

    public var shouldHideActionBar: Bool = false

    // MARK: Internal

    let trustProvider = TrustWeb3Provider.flowConfig()

    lazy var webView: WKWebView = {
        let view = WKWebView(frame: .zero, configuration: generateWebViewConfiguration())
        view.navigationDelegate = self
        view.uiDelegate = self
        view.backgroundColor = commonColor
        view.scrollView.backgroundColor = commonColor
        view.allowsBackForwardNavigationGestures = true
        view.allowsLinkPreview = true
        view.layer.masksToBounds = true
        #if DEBUG
            if #available(iOS 16.4, *) {
                view.isInspectable = true
            }
        #endif
        return view
    }()

    lazy var jsHandler: JSMessageHandler = {
        let obj = JSMessageHandler()
        obj.webVC = self
        return obj
    }()

    lazy var trustJSHandler: TrustJSMessageHandler = {
        let obj = TrustJSMessageHandler()
        obj.webVC = self
        return obj
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupObserver()
        hero.isEnabled = true
        overrideUserInterfaceStyle = .dark
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        reloadBgPaths()
    }

    // MARK: Private

    private var observation: NSKeyValueObservation?
    private var actionBarIsHiddenFlag: Bool = false
    private var cancelSets = Set<AnyCancellable>()

    private var commonColor: UIColor? = UIColor(named: "bg.silver")

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = commonColor
        return view
    }()

    private lazy var bgMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    private lazy var actionBarView: BrowserActionBarView = {
        let view = BrowserActionBarView()

        view.backBtn.addTarget(self, action: #selector(onBackBtnClick), for: .touchUpInside)
        view.homeBtn.addTarget(self, action: #selector(onHomeBtnClick), for: .touchUpInside)
        view.moveBtn.addTarget(self, action: #selector(onMoveAssets), for: .touchUpInside)
        view.reloadBtn.addTarget(self, action: #selector(onReloadBtnClick), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onAddressBarClick))
        view.addressBarContainer.addGestureRecognizer(tapGesture)

        view.bookmarkAction = { [weak self] isBookmark in
            guard let self = self else { return }
            self.onBookmarkAction(isBookmark)
        }
        view.clearCookie = { [weak self] in
            guard let self = self else { return }
            self.onClearCookie()
        }

        return view
    }()

    private func setup() {
        view.backgroundColor = commonColor

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }

        contentView.layer.mask = bgMaskLayer

        setupWebView()
        setupActionBarView()
        setupBlockView()
    }

    private func setupWebView() {
        contentView.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        webView.scrollView.delegate = self
    }

    private func setupActionBarView() {
        contentView.addSubview(actionBarView)
        actionBarView.snp.makeConstraints { make in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.top.equalTo(webView.snp.bottom).offset(0)
            make.bottom.equalToSuperview()
        }
    }

    private func setupBlockView() {
        contentView.addSubview(blockView)
        blockView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalTo(webView)
        }
    }

    private func setupObserver() {
        observation = webView.observe(
            \.estimatedProgress,
            options: .new,
            changeHandler: { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.reloadActionBarView()
                }
            }
        )

        NotificationCenter.default.publisher(for: .networkChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onReloadBtnClick()
            }.store(in: &cancelSets)
    }

    private func reloadBgPaths() {
        bgMaskLayer.frame = contentView.bounds

        let path = UIBezierPath(
            roundedRect: contentView.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 20.0, height: 20.0)
        )
        bgMaskLayer.path = path.cgPath
    }

    private lazy var blockView: BlockedWebsiteView = {
        let view = BlockedWebsiteView()
        view.isHidden = true
        view.reportAction = { [weak self] in
            self?.reportBlockedSite()
        }
        view.ignoreAction = { [weak self] in
            self?.ignoreBlockWarning()
        }
        return view
    }()
}

extension BrowserViewController {
    @objc private func reportBlockedSite() {
        let url = "https://github.com/Outblock/flow-blocklist"
        guard let skipUrl = URL(string: url) else {
            log.warning("skip block list failed.")
            return
        }
        UIApplication.shared.open(skipUrl)
    }

    @objc private func ignoreBlockWarning() {
        if let url = blockView.blockedURL {
            loadAndUpdateUI(url)
        }
    }
}

// MARK: - Load

extension BrowserViewController {
    func loadURL(_ url: URL) {
        guard !BlocklistHandler.shared.inBlacklist(url: url.absoluteString) else {
            blockView.setBlockedURL(url)
            blockView.isHidden = false
            actionBarView.progressView.isHidden = true
            return
        }
        loadAndUpdateUI(url)
    }

    private func loadAndUpdateUI(_ url: URL) {
        blockView.isHidden = true
        actionBarView.progressView.isHidden = false

        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - Action Bar

extension BrowserViewController {
    private func reloadActionBarView() {
        if let title = webView.title, !title.isEmpty {
            actionBarView.addressLabel.text = title
        } else {
            actionBarView.addressLabel.text = webView.url?.absoluteString
        }

        actionBarView.moveBtn.isSelected = webView.isLoading
        actionBarView.reloadBtn.isSelected = webView.isLoading
        actionBarView.progressView.isHidden = !webView.isLoading
        actionBarView.progressView.progress = webView.isLoading ? webView.estimatedProgress : 0

        actionBarView.updateMenu(currentURL: webView.url)
    }

    private func hideActionBarView() {
//        if actionBarIsHiddenFlag {
//            return
//        }
//
//        actionBarIsHiddenFlag = true
//
//        UIView.animate(withDuration: 0.25) {
//            let y = Router.coordinator.window.safeAreaInsets.bottom + 20 + BrowserActionBarViewHeight
//            self.actionBarView.transform = CGAffineTransform(translationX: 0, y: y)
//        }
    }

    private func showActionBarView() {
//        if !actionBarIsHiddenFlag {
//            return
//        }
//
//        actionBarIsHiddenFlag = false
//
//        UIView.animate(withDuration: 0.25) {
//            self.actionBarView.transform = .identity
//        }
    }

    @objc
    private func onBackBtnClick() {
        if webView.canGoBack {
            webView.goBack()
            return
        }

        onHomeBtnClick()
    }

    @objc
    private func onHomeBtnClick() {
        Router.pop()
    }

    @objc
    private func onReloadBtnClick() {
        webView.reload()
    }

    @objc
    private func onMoveAssets() {
        if MoveAssetsAction.shared.allowMoveAssets {
          Router.route(to: RouteMap.ReactNative.selectAssets(nil))
        } else {
            HUD.info(title: "Features Coming Soon")
        }
    }

    @objc
    private func onAddressBarClick() {
        showSearchInputView()
    }

    private func onBookmarkAction(_ isBookmark: Bool) {
        guard let url = webView.url else {
            return
        }

        if isBookmark {
            let bookmark = WebBookmark()
            bookmark.url = url.absoluteString
            bookmark.title = webView.title ?? "bookmark"
            bookmark.createTime = Date().timeIntervalSince1970
            bookmark.updateTime = bookmark.createTime
            DBManager.shared.save(webBookmark: bookmark)
            HUD.success(title: "browser_bookmark_added".localized)
        } else {
            DBManager.shared.delete(webBookmarkByURL: url.absoluteString)
            HUD.success(title: "browser_bookmark_deleted".localized)
        }

        actionBarView.updateMenu(currentURL: webView.url)
    }

    private func onClearCookie() {
        BrowserViewController.deleteCookie()
    }

    private func handleNavigationAction(navigationAction: WKNavigationAction) {
        guard let url = navigationAction.request.url else {
            return
        }

        if !url.absoluteString.hasPrefixes(AppExternalLinks.allLinks) {
            if navigationAction.targetFrame == nil {
                UIApplication.shared.open(url)
            }
            return
        }

        let uri = AppExternalLinks.exactWCLink(link: url.absoluteString)
        WalletConnectManager.shared.onClientConnected = {
            WalletConnectManager.shared.connect(link: uri)
        }
        WalletConnectManager.shared.connect(link: uri)
    }
}

// MARK: - Search Recommend

extension BrowserViewController {
    private func showSearchInputView() {
        let inputVC = BrowserSearchInputViewController()
        inputVC.setSearchText(text: webView.url?.absoluteString)
        inputVC.selectTextCallback = { [weak self] text in
            let urlString = BrowserSearchInputViewController.makeUrlIfNeeded(urlString: text)
            if let url = URL(string: urlString) {
                self?.navigationController?.popViewController(animated: false) {
                    self?.loadURL(url)
                }
            }
        }
        navigationController?.pushViewController(inputVC, animated: false)
    }
}

// MARK: WKNavigationDelegate

extension BrowserViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        reloadActionBarView()
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        reloadActionBarView()

        // For some website there is a overlapping,
        // hence we hide the tool bar at the begining.
        if shouldHideActionBar {
            hideActionBarView()
            shouldHideActionBar = false
        }
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
        reloadActionBarView()
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        reloadActionBarView()
    }

    func webView(
        _: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        handleNavigationAction(navigationAction: navigationAction)
        reloadActionBarView()
        return .allow
    }
}

// MARK: WKUIDelegate

extension BrowserViewController: WKUIDelegate {
    func webView(
        _: WKWebView,
        createWebViewWith _: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures _: WKWindowFeatures
    ) -> WKWebView? {
        handleNavigationAction(navigationAction: navigationAction)
        return nil
    }
}

// MARK: UIScrollViewDelegate

extension BrowserViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y >= 0 {
            showActionBarView()
        } else {
            hideActionBarView()
        }
    }
}

extension BrowserViewController {
    static func deleteCookie() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        let dispatch_group = DispatchGroup()
        WKWebsiteDataStore.default()
            .fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                for record in records {
                    dispatch_group.enter()
                    WKWebsiteDataStore.default().removeData(
                        ofTypes: record.dataTypes,
                        for: [record],
                        completionHandler: {
                            dispatch_group.leave()
                        }
                    )
                    #if DEBUG
                        print("WKWebsiteDataStore record deleted:", record)
                    #endif
                }
                dispatch_group.notify(queue: DispatchQueue.main) {}
            }
    }
}
