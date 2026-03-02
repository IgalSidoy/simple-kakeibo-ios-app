import Foundation
import WebKit
import UIKit

@MainActor
final class CookiePersistence {
    static let shared = CookiePersistence()
    private let storageKey = "wk_persisted_cookies"

    private init() {}

    func save() async {
        let taskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)

        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        let list = cookies.compactMap { CookieData(from: $0) }
        if let encoded = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            UserDefaults.standard.synchronize()
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
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([CookieData].self, from: data)
        else { return }

        let store = WKWebsiteDataStore.default().httpCookieStore
        for entry in list {
            guard let cookie = entry.httpCookie else { continue }
            if let exp = cookie.expiresDate, exp < Date() { continue }
            await store.setCookie(cookie)
        }
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
