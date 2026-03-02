import Foundation
import WebKit
import UIKit
import os

private let log = Logger(subsystem: "com.igals.SimpleKakeibo", category: "CookiePersistence")

@MainActor
final class CookiePersistence {
    static let shared = CookiePersistence()
    private let storageKey = "wk_persisted_cookies"

    private init() {}

    func save() async {
        let taskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)

        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        log.info("💾 SAVE: found \(cookies.count) cookies in WKWebView")
        for c in cookies {
            log.info("  💾 cookie: \(c.name) domain=\(c.domain) path=\(c.path) httpOnly=\(c.isHTTPOnly) secure=\(c.isSecure) expires=\(String(describing: c.expiresDate))")
        }

        let list = cookies.compactMap { CookieData(from: $0) }
        if let encoded = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            UserDefaults.standard.synchronize()
            log.info("💾 SAVE: wrote \(list.count) cookies to UserDefaults (\(encoded.count) bytes)")
        } else {
            log.error("💾 SAVE: encoding failed!")
        }

        if taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
        }
    }

    nonisolated static func saveInBackground() {
        Task { @MainActor in
            await CookiePersistence.shared.save()
        }
    }

    func restore() async {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            log.info("🔄 RESTORE: no saved cookie data in UserDefaults")
            return
        }
        guard let list = try? JSONDecoder().decode([CookieData].self, from: data) else {
            log.error("🔄 RESTORE: failed to decode cookie data")
            return
        }

        log.info("🔄 RESTORE: found \(list.count) saved cookies")

        let store = WKWebsiteDataStore.default().httpCookieStore
        var restored = 0
        var skippedExpired = 0
        var skippedNil = 0
        for entry in list {
            guard let cookie = entry.httpCookie else {
                log.warning("🔄 RESTORE: could not create HTTPCookie from: \(entry.name) domain=\(entry.domain)")
                skippedNil += 1
                continue
            }
            if let exp = cookie.expiresDate, exp < Date() {
                log.info("🔄 RESTORE: skipping expired cookie: \(cookie.name) expired=\(exp)")
                skippedExpired += 1
                continue
            }
            await store.setCookie(cookie)
            restored += 1
            log.info("🔄 RESTORE: set cookie: \(cookie.name) domain=\(cookie.domain) path=\(cookie.path) httpOnly=\(cookie.isHTTPOnly)")
        }
        log.info("🔄 RESTORE: done — restored=\(restored) skippedExpired=\(skippedExpired) skippedNil=\(skippedNil)")
    }
}

// MARK: - Codable cookie wrapper

private struct CookieData: Codable, Sendable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let expires: Date?
    let secure: Bool
    let httpOnly: Bool
    let sameSite: String?

    init?(from cookie: HTTPCookie) {
        name = cookie.name
        value = cookie.value
        domain = cookie.domain
        path = cookie.path
        expires = cookie.expiresDate
        secure = cookie.isSecure
        httpOnly = cookie.isHTTPOnly
        sameSite = cookie.sameSitePolicy?.rawValue
            ?? (cookie.properties?[HTTPCookiePropertyKey("SameSite")] as? String)
    }

    var httpCookie: HTTPCookie? {
        var props: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path.isEmpty ? "/" : path,
        ]
        if let expires { props[.expires] = expires }
        if secure { props[.secure] = "TRUE" }
        if httpOnly { props[HTTPCookiePropertyKey("HttpOnly")] = "TRUE" }
        if let sameSite { props[HTTPCookiePropertyKey("SameSite")] = sameSite }
        return HTTPCookie(properties: props)
    }
}
