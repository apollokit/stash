# Quick Start Guide

Get Stash running on your iPhone/iPad in 2 minutes.

## Prerequisites

- macOS with Xcode 15+
- iOS device or simulator running iOS 16+
- iPhone/iPad connected via USB (for device testing)

## Steps

### 1. Open the Project

```bash
cd ios-app
open Stash.xcodeproj
```

### 2. Select Your Device

- In Xcode, click the device dropdown in the toolbar
- Choose your connected iPhone/iPad or a simulator

### 3. Build and Run

- Press ⌘R (or click the Play button)
- App will install and launch on your device
- Sign in with your Supabase credentials

### 4. Test Share Extension (Real Device Only)

Share extensions only work on physical devices, not simulators.

1. Open Safari on your device
2. Navigate to any webpage
3. Tap the Share button
4. Scroll down and tap "Stash"
5. The Stash app opens with URL and title pre-filled
6. Tap "Save Page"

## Done! 🎉

Your native iOS Stash app is ready to use. You can:
- Save pages manually in the app
- Share from Safari using the Share Extension
- Organize saves into folders
- View your recent saves
- Pull to refresh

## Troubleshooting

**Share extension not appearing?**
- Must use a real device (not simulator)
- Force quit Safari and reopen
- Check Settings → Safari → Extensions and enable Stash

**Build errors?**
- Product > Clean Build Folder (⇧⌘K)
- Restart Xcode

**Can't sign in?**
- Check internet connection
- Verify Supabase credentials in Config.swift
