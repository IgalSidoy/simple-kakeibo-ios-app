import SwiftUI
import WebKit
import UIKit
import os

private let log = Logger(subsystem: "com.igals.SimpleKakeibo", category: "WebView")

/// Loads a URL or inline HTML in a WKWebView with haptic feedback and pull-to-refresh.
struct WebView: UIViewRepresentable {
    var url: URL?
    var html: String?
    var onMessage: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }

    private static let sharedProcessPool = WKProcessPool()

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = Self.sharedProcessPool
        config.websiteDataStore = WKWebsiteDataStore.default()

        let contentController = config.userContentController
        contentController.add(context.coordinator, name: "bridge")
        contentController.add(context.coordinator, name: "haptic")

        let hapticScript = WKUserScript(
            source: Self.hapticInjectionJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(hapticScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator

        config.websiteDataStore.httpCookieStore.add(context.coordinator)

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .white
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefresh(_:)),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refreshControl
        context.coordinator.webView = webView

        if let url {
            log.info("🌐 loading URL: \(url.absoluteString)")
            webView.load(URLRequest(url: url))
        } else if let html {
            log.info("🌐 loading inline HTML")
            webView.loadHTMLString(html, baseURL: nil)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url, webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    private static let hapticInjectionJS = """
    (function() {
        const interactiveSelectors = 'button, a, [role="button"], input[type="submit"], input[type="button"], .clickable';

        document.addEventListener('pointerdown', function(e) {
            if (e.target.closest(interactiveSelectors)) {
                window.webkit.messageHandlers.haptic.postMessage('impact');
            }
        }, { passive: true });
    })();
    """

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKHTTPCookieStoreObserver {
        let onMessage: ((String) -> Void)?
        weak var webView: WKWebView?
        private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)

        init(onMessage: ((String) -> Void)?) {
            self.onMessage = onMessage
            super.init()
            impactGenerator.prepare()
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            webView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sender.endRefreshing()
            }
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            switch message.name {
            case "haptic":
                impactGenerator.impactOccurred()
                impactGenerator.prepare()
            case "bridge":
                if let body = message.body as? String {
                    onMessage?(body)
                }
            default:
                break
            }
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            log.info("🌐 didStartProvisionalNavigation: \(webView.url?.absoluteString ?? "nil")")
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            log.info("🌐 didCommit: \(webView.url?.absoluteString ?? "nil")")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            log.info("🌐 didFinish: \(webView.url?.absoluteString ?? "nil")")
            CookiePersistence.saveInBackground()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            log.error("🌐 didFailProvisionalNavigation: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            log.error("🌐 didFail: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView,
                      didReceive challenge: URLAuthenticationChallenge
        ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
            #if DEBUG
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let trust = challenge.protectionSpace.serverTrust {
                return (.useCredential, URLCredential(trust: trust))
            }
            #endif
            return (.performDefaultHandling, nil)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            log.warning("🌐 webContentProcessDidTerminate — restoring cookies and reloading")
            Task { @MainActor in
                await CookiePersistence.shared.restore()
            }
            webView.reload()
        }

        // MARK: - WKHTTPCookieStoreObserver

        nonisolated func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
            CookiePersistence.saveInBackground()
        }
    }
}
