# GalleryApp

An iOS photo gallery built on the Unsplash API: browse a paginated grid, open a photo to
read its details and swipe through the set, and keep a locally persisted list of favourites.

## Contact

- **Author:** Kirill Pukhov
- **GitHub:** [kirillpukhov2004](https://github.com/kirillpukhov2004)

## Overview

GalleryApp is a UIKit application written in Swift for iOS 17 and above. It fetches curated
photos from Unsplash 30 at a time, caches thumbnails for smooth scrolling, and stores
favourites locally with Core Data. State is carried reactively with Combine, and navigation
is handled by coordinators so view controllers stay free of routing logic.

## Key functionality

- **Gallery** — adaptive grid of thumbnails with pagination triggered near the bottom,
  pull to refresh, loading/empty/error states with retry, and a favourite badge on each
  thumbnail.
- **Detail** — full-width image, title and description in a scrollable panel, heart toggle,
  horizontal swipe through the images already loaded by the gallery, and photographer
  attribution linking to their Unsplash profile. Landscape switches to a split layout with
  the image on the left and the metadata column on the right.
- **Favourites** — the favourited photos in a grid, with removal through a context menu or a
  VoiceOver action, persisted across launches.

## Assumptions and extra features

- The app uses Unsplash's **public authentication** (`Authorization: Client-ID <access key>`).
  No user login or OAuth flow is implemented because the assignment only needs read access.
- The demo rate limit is 50 requests per hour. Each page is fetched once, images are cached,
  and no retry loop hammers the API, so normal browsing stays inside that budget.
- Favourites store **metadata only** (id, title, description, URLs, photographer, size);
  image files are never written to Core Data.
- Beyond the brief: adaptive grid for iPhone and iPad widths, dark mode, Dynamic Type,
  VoiceOver labels and custom actions, non-blocking retry for failed pagination, and
  photographer links.
- **No third-party packages or dependencies.** XcodeGen and SwiftLint are development tools
  only.

## Architecture

```
Presentation   ViewController + ViewModel per screen, coordinators for navigation
Domain         Photo model, PhotoFetching, FavouritesRepositoryProtocol
Data           UnsplashClient and DTOs, Core Data stack and repository
Core           HTTPClient, APIError, image loader, configuration, design system
```

- **MVVM** with `@Published` state and `AnyPublisher` outputs; controllers subscribe with
  `sink` and store cancellables.
- **Coordinator** pattern for navigation; view controllers never push or present.
- **Dependency injection** through initialisers, assembled once in `SceneDelegate` by
  `AppDependencies`.
- **Programme to protocols** (`PhotoFetching`, `FavouritesRepositoryProtocol`, `ImageLoading`,
  `HTTPClient`) so every layer is replaceable and testable.
- A single `FavouritesRepository` publishes favourite IDs to every screen, which is what keeps
  the gallery badge, the detail heart and the favourites grid in sync.

Design patterns in use: Observer (Combine), Delegate (collection view and image loading),
Factory (coordinators and dependency container), Dependency Inversion (protocol boundaries).

### SOLID

- **Single responsibility** — decoding lives in the data layer, formatting and state in view
  models, rendering in view controllers.
- **Open/closed** — new photo sources or endpoints implement the existing protocols.
- **Liskov substitution** — every test double is a drop-in for its protocol.
- **Interface segregation** — small protocols (`ImageLoading`, `PhotoFetching`) instead of
  one broad service.
- **Dependency inversion** — high-level view models depend on abstractions, never concrete
  clients or Core Data types.

### Why these choices

- **MVVM + coordinators** keeps UIKit lifecycle code thin and makes navigation testable and
  centralised.
- **Protocol boundaries** let the whole app run in tests with stubs and an in-memory store,
  with no network and no simulator state leaking between tests.
- **Core Data with a unique `photoID`** keeps favourites consistent, survives relaunches and
  scales beyond a plist or `UserDefaults` list.
- **Downsampled image cache** avoids decoding full-size images for thumbnails, which is the
  main cause of janky grids.

### Frameworks

UIKit, Combine, Core Data, URLSession, XCTest, XcodeGen and SwiftLint.

## Screenshots

Screenshots are captured on the iPhone 17 simulator and stored in `docs/screenshots/`:

```bash
xcrun simctl io booted screenshot docs/screenshots/gallery.png
```

| Gallery | Detail | Favourites |
| --- | --- | --- |
| `docs/screenshots/gallery.png` | `docs/screenshots/detail.png` | `docs/screenshots/favourites.png` |

The development environment used for this build could not render the simulator surface, so
the three images are captured on a workstation with a running Simulator before submission.

## Configuration

The Unsplash access key is not committed. Create the local configuration file first:

```bash
cp GalleryApp/Resources/Config.xcconfig.example GalleryApp/Resources/Config.xcconfig
```

Open `GalleryApp/Resources/Config.xcconfig` and set the **public** access key:

```xcconfig
UNSPLASH_ACCESS_KEY = your-public-access-key
```

Use the key Unsplash shows for public authentication (`Authorization: Client-ID <key>`).
Never put the secret key in this file, in the app, or in a commit. If the key is missing the
app shows a configuration screen instead of crashing.

## Build, test and lint

The Xcode project is generated from `project.yml`:

```bash
xcodegen generate
```

Build:

```bash
xcodebuild -project GalleryApp.xcodeproj -scheme GalleryApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .build build
```

Test:

```bash
xcodebuild -project GalleryApp.xcodeproj -scheme GalleryApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .build test
```

Lint:

```bash
swiftlint --strict
```

## Tests

69 unit tests run without touching the network or the live API.

| Suite | Covers |
| --- | --- |
| `AppConfigurationTests` | access key presence, blank and unresolved values, trimming |
| `HTTPClientTests` | 2xx passthrough, 401/429/5xx mapping, transport and cancellation errors |
| `UnsplashClientTests` | auth headers, pagination query, decoding, short pages, malformed payloads |
| `FavouritesRepositoryTests` | toggle/remove, duplicates, persistence across instances, publishers |
| `ImageLoaderTests` | downsampling, memory cache, in-flight de-duplication, cancellation |
| `GalleryViewModelTests` | initial load, pagination, de-duplication, refresh, retry, favourite IDs |
| `DetailViewModelTests` | index clamping, swipe updates, favourite state, toggle errors |
| `DetailLayoutModeTests` | portrait/landscape selection |
| `DetailViewControllerLayoutTests` | portrait stack, landscape split, rotation alignment, long text |
| `FavouritesViewModelTests` | publisher updates, removal, out-of-range guard, error handling |

Networking tests use `URLProtocol` stubs and JSON fixtures; persistence tests use an
in-memory Core Data store.

## Commit convention

Commits use a bracketed tag, a past-tense verb and a short summary:

| Tag | Use |
| --- | --- |
| `[ADDED]` | new feature or capability |
| `[FIXED]` | bug fix |
| `[REFACTORED]` | restructuring without behaviour change |
| `[UPDATED]` | changed behaviour or dependency |
| `[TESTED]` | tests only |
| `[DOCS]` | documentation only |
| `[CHORE]` | tooling, project configuration |

Example: `[ADDED] paginated gallery grid`.

Work happens on `feat/`, `fix/`, `chore/`, `test/` and `docs/` branches, one pull request
per slice, merged into `main`.
