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

### Setup (5 minutes)

1. **Create Xcode Project**
   - Follow [SETUP.md](SETUP.md) to create the project
   - Add all `.swift` files to your project
   - Add Supabase Swift package dependency

2. **Run the App**
   - Select your device in Xcode
   - Press ⌘R
   - Sign in with your Supabase credentials

3. **Add Share Extension** (optional, for Safari sharing)
   - Follow [SHARE_EXTENSION_SETUP.md](SHARE_EXTENSION_SETUP.md)
   - Allows sharing from Safari, News, any app with URLs

### That's It!

No Metro bundler, no npm packages, no build configuration hell. Just pure Swift.

## Project Structure

```
ios-app/
├── Stash/                          # Main app (created by Xcode)
│   ├── StashApp.swift              # App entry point
│   ├── Config.swift                # Supabase config
│   ├── Models.swift                # Data models (Save, Folder)
│   ├── SupabaseService.swift       # API client
│   ├── AuthView.swift              # Login/signup screen
│   ├── HomeView.swift              # Main screen with save form
│   ├── SaveItemRow.swift           # Save list item
│   └── FolderSelector.swift        # Folder picker modal
├── StashShareExtension/            # Share Extension (optional)
│   └── ShareViewController.swift   # Handles Safari sharing
├── SETUP.md                        # Setup instructions
├── SHARE_EXTENSION_SETUP.md        # Share Extension guide
└── README.md                       # This file
```

## Git Workflow

Everything is version controlled:

```bash
# Initial setup
git add ios-app/
git commit -m "Add native iOS app"
git push

# On a new machine
git clone <repo>
cd stash/ios-app
open Stash.xcodeproj
# Press Run - done!
```

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

Supabase credentials are in `Config.swift`:

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

- Make sure Supabase package is added
- Clean build folder: Product > Clean Build Folder (⇧⌘K)
- Restart Xcode

### Share Extension Not Appearing

- Must build on real device (not simulator)
- Check that URL scheme "stash" is configured
- Force quit Safari and reopen

### Authentication Issues

- Check Config.swift has correct Supabase credentials
- Verify user exists in Supabase dashboard
- Check internet connection

## Next Steps

1. Follow [SETUP.md](SETUP.md) to create the Xcode project
2. Add Swift files to your project
3. Run and test the app
4. Add Share Extension following [SHARE_EXTENSION_SETUP.md](SHARE_EXTENSION_SETUP.md)
5. Start saving articles!

## Support

Everything you need is in this directory. No external dependencies except Supabase Swift package.
