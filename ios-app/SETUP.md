# Stash iOS App Setup

> **Note:** This file is for historical reference only. The Xcode project is already configured and ready to use. See [QUICKSTART.md](QUICKSTART.md) instead.

## Quick Start (New Users)

The Xcode project (`Stash.xcodeproj`) is already fully configured with all source files, the Share Extension, and dependencies.

```bash
cd ios-app
open Stash.xcodeproj
# Press ⌘R to build and run
```

That's it! No manual setup required.

---

## Original Setup Instructions (Historical)

This section documents how the project was originally created. **You don't need to follow these steps** - they're kept here for reference only.

<details>
<summary>Click to expand original setup instructions</summary>

### 1. Create the Xcode Project

1. Open Xcode
2. File > New > Project
3. Choose **iOS > App**
4. Settings:
   - Product Name: **Stash**
   - Team: Your Apple Developer team
   - Organization Identifier: **com.kitkennedy**
   - Bundle Identifier: **com.kitkennedy.StashApp**
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Save to `ios-app` directory

### 2. Add Supabase Package

1. File > Add Package Dependencies
2. URL: `https://github.com/supabase/supabase-swift`
3. Version: Up to Next Major (2.0.0)
4. Add to target: Stash

### 3. Add Source Files

All Swift files are already in the Xcode project structure:
- `Stash/Stash/*.swift` - Main app files
- `Stash/StashShareExtension/ShareViewController.swift` - Share Extension

### 4. Configure Share Extension

The Share Extension target is already configured with:
- Info.plist settings for URL handling
- Deep link URL scheme (stash://)
- Proper module naming for Swift classes

</details>
