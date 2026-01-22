# Stash iOS App Setup

This is a native Swift/SwiftUI app for iPhone and iPad.

## Quick Start

### 1. Create the Xcode Project

1. Open Xcode
2. File > New > Project
3. Choose **iOS > App**
4. Settings:
   - Product Name: **Stash**
   - Team: Your Apple Developer team
   - Organization Identifier: **com.kitkennedy**
   - Bundle Identifier: **com.kitkennedy.stash** (auto-filled)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - ✓ Include Tests: Uncheck
5. Save location: **Select this `ios-app` directory**
6. Create

### 2. Configure Project Settings

1. Select the Stash project in the navigator
2. Select the **Stash** target
3. Under **Deployment Info**:
   - ✓ Check both **iPhone** and **iPad**
   - Minimum Deployments: **iOS 16.0**

### 3. Add Swift Package Dependencies

1. File > Add Package Dependencies
2. Add Supabase:
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Up to Next Major Version (2.0.0)
   - Add to target: Stash

### 4. Copy Source Files

Copy all the `.swift` files from this directory into your Xcode project:
- Drag them into the Xcode navigator
- ✓ Check "Copy items if needed"
- ✓ Add to target: Stash

### 5. Update Config

Edit `Config.swift` and add your Supabase credentials.

### 6. Run

Press ⌘R or click Run. The app should build and run on your device!

## Adding Share Extension (Next Step)

After the main app works, we'll add the Share Extension following `SHARE_EXTENSION_SETUP.md`.

## Project Structure

```
ios-app/
├── Stash/                    # Xcode creates this
│   ├── StashApp.swift        # App entry point (replace with provided file)
│   ├── Config.swift          # Supabase configuration (provided)
│   ├── Models/
│   │   └── Models.swift      # Data models (provided)
│   ├── Services/
│   │   └── SupabaseService.swift  # API service (provided)
│   └── Views/
│       ├── AuthView.swift         # Login/signup (provided)
│       ├── HomeView.swift         # Main screen (provided)
│       ├── SaveItemRow.swift      # List item (provided)
│       └── FolderSelector.swift   # Folder picker (provided)
└── StashShareExtension/      # Add later for Safari sharing
```

## Git Workflow

Everything is tracked in git:
```bash
git add ios-app/
git commit -m "Add native iOS app"
```

To clone and run on a new machine:
```bash
git clone <repo>
cd stash/ios-app
open Stash.xcodeproj
# Press Run in Xcode
```
