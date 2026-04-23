# Rally

A native iOS app for car enthusiasts to discover, create, and RSVP to local events — car meets, track days, shows, scenic drives, and more.

## Features

- **Map view** — browse nearby events as live pins on an interactive map
- **Event feed** — scrollable list with category filters and real-time search
- **Trending section** — horizontal carousel highlighting the most popular upcoming events
- **Distance filter** — narrow the feed to events within 10, 25, or 50 miles
- **Event creation** — pick a location on the map, set a date, choose a category
- **RSVP** — one-tap attendance tracking synced in real time
- **Share events** — native iOS share sheet with event details
- **Google Sign-In** — authentication with profile picture pulled from your Google account
- **Light / Dark / System theme** — per-device appearance preference saved across launches

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI (iOS 17+) |
| Auth | Google Sign-In + Firebase Auth |
| Database | Cloud Firestore |
| Maps | MapKit |
| Location | CoreLocation |
| Build | XcodeGen |

## Getting Started

### Prerequisites

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- A Firebase project with iOS app configured
- Google Sign-In OAuth client ID

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/rhmn07/Rally.git
   cd Rally
   ```

2. Add your Firebase config file:
   - Download `GoogleService-Info.plist` from the Firebase console
   - Place it at `Rally/GoogleService-Info.plist`

3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

4. Open and run:
   ```bash
   open Rally.xcodeproj
   ```
   Select a simulator or device and press **Run**.

## Project Structure

```
Rally/
├── App/
│   └── ContentView.swift       # Root tab view
├── Models/
│   ├── Event.swift             # RallyEvent + EventCategory
│   └── AppUser.swift           # User profile model
├── ViewModels/
│   ├── AuthViewModel.swift     # Google Sign-In + Firebase Auth state
│   ├── EventsViewModel.swift   # Events feed, filters, trending, RSVP
│   └── MapViewModel.swift      # Map camera state
├── Views/
│   ├── Auth/                   # Sign-in screen
│   ├── Feed/                   # Events list + trending carousel
│   ├── Event/                  # Detail, creation, location picker
│   ├── Map/                    # Map tab, pins, callouts
│   └── Profile/                # User profile + appearance settings
├── Services/
│   ├── FirebaseService.swift   # Firestore read/write operations
│   └── LocationService.swift  # CoreLocation wrapper
└── Components/
    └── CategoryBadge.swift     # Reusable category label
```

## License

MIT
