# Hablas Virtual Studio 🧊

> **Unlimited Android App Cloning & Virtualization Platform**

[![Build & Release](https://github.com/Monopoly63/hablas_clone/actions/workflows/build_and_release.yml/badge.svg)](https://github.com/Monopoly63/hablas_clone/actions/workflows/build_and_release.yml)
[![Version](https://img.shields.io/badge/version-1.0.0-cyan)](https://github.com/Monopoly63/hablas_clone/releases/tag/v1.0.0)
[![Platform](https://img.shields.io/badge/platform-Android-black)]()
[![License](https://img.shields.io/badge/license-Proprietary-red)]()

## 🌟 Overview

Hablas Virtual Studio is a production-grade, unlimited application cloning and virtualization platform. Unlike simple APK repackagers, it utilizes a native **In-Process Virtual Sandbox Engine** that allows running infinite isolated parallel instances of any installed Android application directly inside the container — without modifying or re-installing native APKs.

### Key Guarantees

| Feature | Status |
|---------|--------|
| 🔒 Absolute State & Session Persistence | ✅ Zero session drops |
| 🔄 Infinite Instance Provisioning | ✅ Unlimited clones |
| 🧊 Liquid Glass UI/UX | ✅ OLED Deep Black + Glassmorphism |
| 🏗️ Native Virtualization Engine | ✅ Kotlin/NDK scaffolding |
| 🚀 CI/CD Pipeline | ✅ GitHub Actions auto-release |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter UI Layer                          │
│  ┌──────────┐  ┌───────────┐  ┌──────────────────┐        │
│  │Dashboard │  │App Picker │  │Instance Settings │        │
│  └──────────┘  └───────────┘  └──────────────────┘        │
│         │              │               │                     │
│    ┌────┴──────────────┴───────────────┴────┐              │
│    │         MethodChannel Bridge           │              │
│    │      (com.hablas.studio/engine)        │              │
│    └────────────────┬───────────────────────┘              │
├─────────────────────┼─────────────────────────────────────┤
│                     │                                       │
│    ┌────────────────┴───────────────────────┐              │
│    │      Virtual Engine Manager            │              │
│    └────────────────────────────────────────┘              │
│         │         │          │          │                    │
│    ┌────┴───┐ ┌───┴───┐ ┌───┴──────┐ ┌──┴────────┐      │
│    │VPM Hook│ │VAM    │ │File      │ │Foreground │      │
│    │        │ │Hook   │ │Redirector│ │Service    │      │
│    └────────┘ └───────┘ └──────────┘ └───────────┘      │
│                                                           │
│    ┌──────────────────────────────────────────┐          │
│    │    Sandbox: /virtual/sandbox/{app}_{id}/ │          │
│    │    ├── shared_prefs                       │          │
│    │    ├── databases                          │          │
│    │    ├── cache                              │          │
│    │    ├── files                              │          │
│    │    └── code_cache                         │          │
│    └──────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

---

## 🧊 Liquid Glass Design System

| Token | Value | Usage |
|-------|-------|-------|
| OLED Black | `#050505` | Background |
| Liquid Cyan | `#00F2FE` | Primary accent |
| Cobalt Blue | `#4FACFE` | Secondary accent |
| Neon Emerald | `#00FF87` | Status: Running |
| Neon Pink | `#FF006E` | Status: Error / Danger |
| Glass Fill | `10% white` | Card backgrounds |
| Glass Border | `20% white` | Card borders |
| Glass Blur | `σ=20` | BackdropFilter |

---

## 📱 Screens

### Dashboard
- Grid view of virtual instances with real-time status badges (🟢 Running, 🔵 Idle, 🌙 Sleeping)
- Storage & memory monitor cards per application group
- Instant launch/terminate controls
- Floating "+" action button for cloning new apps

### App Picker
- Searchable list of all installed apps
- Popular clone targets (WhatsApp, Telegram, Instagram) prioritized
- Single-tap instant cloning
- System app toggle filter

### Instance Settings (Coming in v1.1)
- Custom naming (e.g., "WhatsApp — Work")
- Home screen shortcut creation
- Notification & permission management
- Cache clearing

---

## 🔧 Project Structure

```
hablas_virtual_studio/
├── .github/workflows/
│   └── build_and_release.yml
├── android/app/src/main/kotlin/com/hablas/studio/
│   ├── MainActivity.kt
│   └── engine/
│       ├── VirtualEngineManager.kt
│       ├── hooks/
│       │   ├── ActivityManagerHook.kt
│       │   └── PackageManagerHook.kt
│       └── sandbox/
│           └── FileRedirector.kt
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/app_constants.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── glass_decorations.dart
│   │   │   └── liquid_shader_painter.dart
│   │   └── native_bridge/
│       │   └── virtual_engine_bridge.dart
│   └── features/
│       ├── dashboard/
│       │   ├── domain/virtual_instance.dart
│       │   └── presentation/
│       │       ├── bloc/dashboard_bloc.dart
│       │       ├── screens/dashboard_screen.dart
│       │       └── widgets/glass_instance_card.dart
│       └── app_picker/
│           ├── domain/
│           │   ├── installed_app.dart
│           │   └── app_picker_repository.dart
│           └── presentation/screens/
│               └── app_picker_screen.dart
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Android SDK (API 24+)
- Java 17
- Kotlin 1.9+

### Build & Run
```bash
git clone https://github.com/Monopoly63/hablas_clone.git
cd hablas_clone
flutter pub get
flutter run
```

### Build Release APK
```bash
flutter build apk --release
```

---

## 🔄 CI/CD

The GitHub Actions workflow automatically:
1. Sets up Java 17 + Flutter stable
2. Installs dependencies
3. Runs tests
4. Builds release APK (with split-per-ABI)
5. Creates a GitHub Release with auto-generated release notes

Triggered by:
- Pushing a `v*.*.*` tag
- Manual workflow dispatch

---

## 📜 Version History

| Version | Date | Notes |
|---------|------|-------|
| v1.0.0 | 2026-07-26 | Initial release — Liquid Glass UI, engine scaffolding, CI/CD |

---

## ⚠️ Security Notice

> **This repository uses encrypted secrets for CI/CD. Never expose GitHub tokens, API keys, or signing certificates in source code.**

---

## 🏛️ License

Proprietary — All rights reserved by Hablas Studio.

---

*Built with 💎 Liquid Glass · Powered by ⚡ Virtual Engine · Crafted with ❤️*
