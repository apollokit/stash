# Share Extension Setup

> **Note:** This file is for historical reference only. The Share Extension is already configured in the Xcode project. See [QUICKSTART.md](QUICKSTART.md) to test it.

## Quick Start (New Users)

The Share Extension is already fully configured and included in the Xcode project. Just build and run:

```bash
cd ios-app
open Stash.xcodeproj
# Press ⌘R to build and run
```

Then test it:
1. Open Safari on your device
2. Navigate to any webpage
3. Tap Share → Stash
4. App opens with URL pre-filled

That's it!

---

## Original Setup Instructions (Historical)

This section documents how the Share Extension was originally configured. **You don't need to follow these steps** - they're kept here for reference only.

<details>
<summary>Click to expand original setup instructions</summary>

### Add Share Extension Target

1. In Xcode, click + at bottom of TARGETS
2. Choose: iOS > Share Extension
3. Name: **StashShareExtension**
4. Click Activate when prompted

### Configure Info.plist

The Share Extension's Info.plist is configured with:
- `NSExtensionPrincipalClass`: `$(PRODUCT_MODULE_NAME).ShareViewController`
- `NSExtensionActivationSupportsWebURLWithMaxCount`: `1`
- `NSExtensionPointIdentifier`: `com.apple.share-services`

### Add URL Scheme

The main app's Info.plist is configured with:
- URL Scheme: `stash`
- Identifier: `com.kitkennedy.StashApp`

This allows the Share Extension to deep link back to the main app.

### Share Config.swift

`Config.swift` has target membership for both:
- ✓ Stash (main app)
- ✓ StashShareExtension

This allows both targets to access Supabase credentials.

</details>

## How It Works

The Share Extension flow:

```
Safari → User taps Share → Stash
  ↓
ShareViewController receives URL + title
  ↓
Creates deep link: stash://save?url=...&title=...
  ↓
Opens main Stash app
  ↓
HomeView.onOpenURL handles deep link
  ↓
Pre-fills save form with URL and title
```

All of this is already implemented and working in the project.
