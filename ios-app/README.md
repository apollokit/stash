# Stash iOS App

Native Swift/SwiftUI app for iPhone and iPad.

## Features

- ✅ Sign in/sign up with Supabase authentication
- ✅ Save web pages with URL and title
- ✅ Organize saves into folders
- ✅ View recent saves
- ✅ Safari Share Extension (share from any app!)
- ✅ iPad support (same codebase)
- ✅ Pull to refresh
- ✅ Clean, native iOS design

## Quick Start

### Prerequisites

- macOS with Xcode 15+
- iOS device or simulator running iOS 16+
- Supabase account (already configured)

### Setup (2 minutes)

1. **Open the Xcode Project**
   ```bash
   cd ios-app
   open Stash.xcodeproj
   ```

2. **Run the App**
   - Select your device or simulator in Xcode
   - Press ⌘R
   - Sign in with your Supabase credentials

### That's It!

The Xcode project is already configured with all source files and the Share Extension. No Metro bundler, no npm packages, no build configuration hell. Just pure Swift.

## Project Structure

```
ios-app/
├── Stash.xcodeproj/                # Xcode project (version controlled)
├── Stash/                          # Main app target
│   ├── Stash/
│   │   ├── StashApp.swift          # App entry point
│   │   ├── Config.swift            # Supabase config
│   │   ├── Models.swift            # Data models (Save, Folder)
│   │   ├── SupabaseService.swift   # API client
│   │   ├── AuthView.swift          # Login/signup screen
│   │   ├── HomeView.swift          # Main screen with save form
│   │   ├── SaveItemRow.swift       # Save list item
│   │   └── FolderSelector.swift    # Folder picker modal
│   └── StashShareExtension/        # Share Extension target
│       ├── ShareViewController.swift  # Handles Safari sharing
│       └── Info.plist              # Extension configuration
├── ARCHITECTURE.md                 # Architecture overview
├── QUICKSTART.md                   # Quick start checklist
└── README.md                       # This file
```

## Git Workflow

The entire Xcode project is version controlled:

```bash
# On a new machine
git clone <repo>
cd stash/ios-app
open Stash.xcodeproj
# Press ⌘R to build and run - done!
```

All source files, project settings, and configurations are tracked in git. No manual setup required.

## Development

### Running on Device

1. Connect iPhone/iPad via USB
2. Select device in Xcode
3. Build and run (⌘R)

### Running on Simulator

1. Select iPhone or iPad simulator
2. Build and run (⌘R)

### Testing Share Extension

Share Extensions only work on **real devices**, not simulators:

1. Build and run on your iPhone/iPad
2. Open Safari
3. Navigate to any webpage
4. Tap Share → Stash
5. App opens with URL pre-filled!

## Configuration

Supabase credentials are in [Stash/Stash/Config.swift](Stash/Stash/Config.swift):

```swift
enum Config {
    static let supabaseURL = "https://your-project.supabase.co"
    static let supabaseAnonKey = "your-anon-key"
}
```

Already configured with your project.

## Why Swift vs React Native?

We originally tried React Native/Expo but hit:
- Metro bundler connection issues
- Complex build configuration
- Difficult debugging
- Multiple layers of abstraction

**Native Swift is:**
- ✅ Simpler setup (no bundler, no npm)
- ✅ Faster performance
- ✅ Easier debugging with Xcode
- ✅ Better iOS integration
- ✅ Smaller app size
- ✅ More reliable
- ✅ Everything in git (no generated code)

For an iOS-only app, native is the way to go.

## Troubleshooting

### Build Errors

- Clean build folder: Product > Clean Build Folder (⇧⌘K)
- Restart Xcode
- Verify Supabase Swift package is properly linked

### Share Extension Not Appearing

- Must build on real device (not simulator)
- Force quit Safari and reopen
- Check Settings → Safari → Extensions and enable Stash

### Authentication Issues

- Check Config.swift has correct Supabase credentials
- Verify user exists in Supabase dashboard
- Check internet connection

## Support

Everything you need is in this directory. The Xcode project is fully configured and ready to run.
