# GalleryApp

An iOS photo gallery built on the Unsplash API: browse a paginated grid, open a photo to
read its details and swipe through the set, and keep a locally persisted list of favourites.

> **Status:** gallery and detail screens are implemented on top of networking, persistence
> and image loading. Favourites is the last screen.

## Contact

- **Author:** _add your name_
- **GitHub:** _add your profile link_

## Overview

GalleryApp is a UIKit application written in Swift for iOS 17 and above. It fetches curated
photos from Unsplash 30 at a time, caches thumbnails for smooth scrolling, and stores
favourites locally with Core Data. State is carried reactively with Combine, and navigation
is handled by coordinators so view controllers stay free of routing logic.

## Key functionality

- **Gallery** — adaptive grid of thumbnails with pagination triggered near the bottom,
  pull to refresh, loading/empty/error states, and a favourite badge on each thumbnail.
- **Detail** — full-width image, title and description, heart toggle, horizontal swipe
  through the images already loaded by the gallery, and photographer attribution linking to
  their Unsplash profile.
- **Favourites** — the favourited photos in a grid, with removal, persisted across launches.

## Assumptions and extra features

- The app uses Unsplash's **public authentication** (`Authorization: Client-ID <access key>`).
  No user login or OAuth flow is implemented because the assignment only needs read access.
- The publicly documented demo rate limit is 50 requests per hour. Pages are fetched once
  and images are cached, so normal browsing stays well inside that budget.
- _Additional features beyond the brief will be listed here as they are added._

## Architecture

```
Presentation   ViewController + ViewModel per screen, coordinators for navigation
Domain         Photo model, protocols, use cases
Data           Unsplash client, Core Data stack and favourites repository
Core           Networking, image loading and caching, configuration, design system
```

- **MVVM** with `@Published` state and `AnyPublisher` outputs; controllers subscribe with
  `sink` and store cancellables.
- **Coordinator** pattern for navigation; view controllers never push or present.
- **Dependency injection** through initialisers, assembled once in `SceneDelegate`.
- **Programme to protocols** (`PhotoFetching`, `FavouritesRepositoryProtocol`, `ImageLoading`,
  `HTTPClient`) so every layer is replaceable and testable.

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

### Frameworks

UIKit, Combine, Core Data, URLSession, XCTest, XcodeGen and SwiftLint.
**No third-party packages or dependencies.**

## Screenshots

Screenshots are added in the documentation milestone:

| Gallery | Detail | Favourites |
| --- | --- | --- |
| _pending_ | _pending_ | _pending_ |

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
Never put the secret key in this file, in the app, or in a commit.

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

| Suite | Covers |
| --- | --- |
| `AppConfigurationTests` | access key presence, blank and unresolved values, trimming |
| `HTTPClientTests` | 2xx passthrough, 401/429/5xx mapping, transport and cancellation errors |
| `UnsplashClientTests` | auth headers, pagination query, decoding, short pages, malformed payloads |
| `FavouritesRepositoryTests` | toggle/remove, duplicates, persistence across instances, publishers |
| `ImageLoaderTests` | downsampling, memory cache, in-flight de-duplication, cancellation |
| `GalleryViewModelTests` | initial load, pagination, de-duplication, refresh, retry, favourite IDs |
| `DetailViewModelTests` | index clamping, swipe updates, favourite state, toggle errors |

Later milestones add one suite per view model plus a full suite for the persistence layer.
Tests use `URLProtocol` stubs and JSON fixtures and never call the live API.

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
