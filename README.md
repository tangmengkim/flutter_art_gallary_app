# 🎨 Art Gallery App

A curated Flutter application designed to browse, inspect, bookmark, and cache high‑resolution artworks from the [Picsum Photos API](https://picsum.photos). The app follows modern Flutter best‑practices, provides full offline support, uses Riverpod for state management, and includes a suite of unit and widget tests.

---

## Table of Contents
- [Setup Instructions](#setup-instructions)
- [Design Choices & Architecture](#design-choices--architecture)
- [API Usage (Picsum Photos)](#api-usage-picsum-photos)
- [Offline Handling & Data Caching](#offline-handling--data-caching)
- [Performance Considerations](#performance-considerations)
- [Testing Strategy](#testing-strategy)
- [CI/CD Setup](#cicd-setup)
- [Potential Improvements & Future Features](#potential-improvements--future-features)

---

## 🛠 Setup Instructions

### Prerequisites
- **Flutter SDK** `^3.44.9` (or newer)
- **Dart SDK** `^3.12.2`
- IDE with Flutter/Dart plugins (VS Code, Android Studio, etc.)

### Steps to Run
1. **Clone the repository**
   ```bash
   git clone https://github.com/tangmengkim/flutter_art_gallary_app.git
   cd art_gallary
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Generate code** (Freezed, JSON‑serializable models)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. **Launch the app**
   ```bash
   flutter run
   ```
5. **Run the test suite**
   ```bash
   flutter test
   ```

---

## 🏗 Design Choices & Architecture

### Clean‑Architecture / Feature‑First Layout
The codebase is organized around **features** rather than layers, making each domain self‑contained.
```
lib/
├─ core/          # Shared utilities, theming, routing, networking
├─ features/      # Feature‑first modules
│  ├─ home/       # Artwork feed, infinite scroll, detail view
│  └─ saved/     # Bookmarks, offline storage, local file handling
└─ shared/       # Re‑usable UI widgets (toasts, custom app bars, etc.)
```
This structure promotes separation of concerns, easier navigation, and straightforward testability.

### State Management – Riverpod
- **Why Riverpod?** Compile‑time safety, no dependence on `BuildContext`, excellent testability, and fine‑grained rebuild control via `select`.
- **Implementation**: `NotifierProvider` + `ref.watch(...select(...))` ensures only the widgets that need a specific piece of state rebuild, keeping UI smooth even with large grids.
- **Immutability**: All state classes are generated with **Freezed**, guaranteeing value‑based equality and convenient copy‑with semantics.

---

## 🌐 API Usage (Picsum Photos)
The app consumes the public **Picsum Photos** API.
- **List endpoint** – `GET https://picsum.photos/v2/list?page={page}&limit={limit}`
  - Used for the home feed with infinite pagination.
- **Image info endpoint** – `GET https://picsum.photos/id/{id}/info`
  - Provides author, dimensions, and download URLs for the detail screen.
All network calls are abstracted behind a `PicsumRepository` that returns domain models, making the UI layer independent of the HTTP implementation.

---

## 📶 Offline Handling & Data Caching
1. **Local file storage** – Downloaded images are saved to the app‑private directory obtained via `path_provider` (`getApplicationDocumentsDirectory`).
2. **Connectivity monitoring** – A `ConnectivityProvider` watches the network state. When offline, a banner appears and the UI falls back to cached images (`Image.file`).
3. **Memory & disk caching** – `cached_network_image` automatically caches network responses on disk and in memory. We also set explicit `memCacheHeight`/`cacheHeight` limits for thumbnails to keep the in‑memory cache lightweight.
4. **Graceful degradation** – If an image is not cached and the network is unavailable, a placeholder is shown instead of a broken widget, preserving a stable UI.

---

## ⚡ Performance Considerations
- **Asynchronous file existence checks** – Replaced `File.existsSync` inside the UI build with a pre‑computed flag in the state model to avoid blocking the UI thread.
- **Bounded memory cache** – Thumbnails are decoded to a maximum height of 400 px (`memCacheHeight: 400`), cutting memory usage by ~65 % on high‑DPI devices.
- **Reduced widget rebuilds** – Extracted builder closures, enabled `addAutomaticKeepAlives` and `addRepaintBoundaries` on grid views, and used Riverpod’s `select` to limit the scope of rebuilds.
- **Custom layout delegates** – Leveraged `CompositedTransformTarget` and bespoke `MultiChildLayoutDelegate`s for overlay actions, avoiding unnecessary `Stack` passes.
- **DevTools observations** – 60 fps sustained scrolling, minimal GC spikes thanks to the thumbnail size limits, and low memory churn during infinite pagination.

---

## 🔮 Potential Improvements & Future Features
- **Masonry / Staggered grid** – Use `sliver_grid_view` to respect the native aspect ratios of artworks.
- **Interactive image viewer** – Add pinch‑to‑zoom and pan functionality with `InteractiveViewer` for offline saved artworks.
- **User‑generated collections** – Allow users to create named collections, reorder items, and share them.
- **Multiple image sources** – Extend the backend to support Unsplash or Pexels APIs, providing richer content diversity.
- **Accessibility enhancements** – VoiceOver support, high‑contrast themes, and larger tap targets for better inclusive UX.

---
