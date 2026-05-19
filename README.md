# Wander

A native SwiftUI iOS 26 app with a glass-effect tab bar, built with Swift 6.

## Requirements

- Xcode 16+ (iOS 18 SDK)
- Swift 6
- iOS 18.0+ deployment target

## Structure

```
Wander/
├── WanderApp.swift       # @main entry point
├── ContentView.swift     # TabView (.sidebarAdaptable) — 3 tabs
├── GlobeTab.swift        # Globe tab content
├── MapTab.swift          # Map tab content
├── SettingsTab.swift     # Settings tab content
├── Info.plist
└── Assets.xcassets/
    ├── AppIcon.appiconset/
    └── AccentColor.colorset/
```

## Tabs

| Tab | Icon (SF Symbol) | Purpose |
|-----|-----------------|---------|
| 1   | `globe`         | Globe   |
| 2   | `map`           | Map     |
| 3   | `gearshape`     | Settings |

## Building locally

Open `Wander.xcodeproj` in Xcode 16+, select an iOS simulator or device, and press **⌘R**.

## GitHub Actions

Every push to `main` triggers `.github/workflows/build.yml`, which:

1. Builds the app for `iphoneos` with **no code signing**
2. Packages it into a `.ipa` (Sideloadly / SideStore compatible)
3. Uploads `Wander.ipa` as a downloadable GitHub Actions artifact (retained 30 days)

## Sideloading

Download `Wander.ipa` from the GitHub Actions run artifacts page and use [Sideloadly](https://sideloadly.io/) or [SideStore](https://sidestore.io/) to install it on your device.
