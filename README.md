# Simple Kakeibo — iOS App

Native iOS wrapper for the [Simple Kakeibo](https://app.ymym.io/) web app, built with SwiftUI and WKWebView.

## Features

- Full-screen WKWebView loading the hosted React web app
- Cookie persistence across app restarts (works around iOS 17+ WKWebView bugs)
- Automatic token refresh via httpOnly cookies
- Pull-to-refresh
- Haptic feedback on interactive elements
- Offline detection with a friendly fallback screen
- Shared `WKProcessPool` for consistent session handling

## Requirements

- macOS with Xcode 16+
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

## Getting Started

```bash
brew install xcodegen   # one-time
xcodegen generate
open SimpleKakeibo.xcodeproj
```

Select a simulator or device, then press **Cmd+R** to build and run.

## Project Structure

```
SimpleKakeibo/
├── SimpleKakeiboApp.swift   # App entry point, saves cookies on background
├── ContentView.swift        # Root view, restores cookies before showing WebView
├── WebView.swift            # WKWebView wrapper with navigation & cookie observer
├── CookiePersistence.swift  # Saves/restores WKWebView cookies via UserDefaults
├── NetworkMonitor.swift     # NWPathMonitor wrapper for connectivity status
├── OfflineView.swift        # Displayed when the device is offline
├── Assets.xcassets/         # App icon, accent color, launch background
└── Info.plist
```

## Regenerating the Xcode Project

After modifying `project.yml` or adding/removing files:

```bash
xcodegen generate
```
