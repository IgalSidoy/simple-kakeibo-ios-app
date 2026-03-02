# TemplateApp

A simple SwiftUI iOS app starter project.

## Requirements

- macOS with Xcode 16+ installed
- iOS 17.0+ deployment target

## Getting Started

1. Open `TemplateApp.xcodeproj` in Xcode
2. Select a simulator (e.g. iPhone 16)
3. Press Cmd+R to build and run

## Project Structure

- `TemplateApp/TemplateAppApp.swift` — App entry point
- `TemplateApp/ContentView.swift` — Main UI (Home tab with counter, Settings tab with form)
- `TemplateApp/Assets.xcassets/` — Asset catalog (app icon, accent color)
- `project.yml` — XcodeGen spec (regenerate with `xcodegen generate`)

## Regenerating the Xcode Project

If you modify `project.yml` or add new files:

```bash
brew install xcodegen  # one-time
xcodegen generate
```
