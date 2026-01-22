# Quick Start Checklist

Follow these steps in order to get Stash running on your iPhone/iPad.

## Part 1: Main App (15 minutes)

### 1. Create Xcode Project
- [ ] Open Xcode
- [ ] File > New > Project
- [ ] Choose: iOS > App
- [ ] Product Name: **Stash**
- [ ] Organization Identifier: **com.kitkennedy**
- [ ] Interface: **SwiftUI**, Language: **Swift**
- [ ] Save in: `ios-app` directory
- [ ] ✓ Check both iPhone and iPad deployment

### 2. Add Supabase Package
- [ ] File > Add Package Dependencies
- [ ] URL: `https://github.com/supabase/supabase-swift`
- [ ] Version: Up to Next Major (2.0.0)
- [ ] Add to target: Stash

### 3. Add Swift Files
Drag these files into Xcode (check "Copy items if needed"):
- [ ] Config.swift
- [ ] Models.swift
- [ ] SupabaseService.swift
- [ ] StashApp.swift (replace the default one)
- [ ] AuthView.swift
- [ ] HomeView.swift
- [ ] SaveItemRow.swift
- [ ] FolderSelector.swift

### 4. Run It!
- [ ] Connect your iPhone/iPad via USB
- [ ] Select your device in Xcode
- [ ] Press ⌘R (or click Run)
- [ ] Sign in with your Supabase account
- [ ] Test saving a page

## Part 2: Share Extension (10 minutes)

### 5. Add Share Extension Target
- [ ] In Xcode, click + at bottom of TARGETS
- [ ] Choose: iOS > Share Extension
- [ ] Name: **StashShareExtension**
- [ ] Click Activate when prompted

### 6. Replace Share Extension Files
- [ ] Delete `ShareViewController.swift` from extension (Move to Trash)
- [ ] Delete `MainInterface.storyboard` (Move to Trash)
- [ ] Add new `ShareViewController.swift` from ios-app folder

### 7. Configure Share Extension
- [ ] Select StashShareExtension target
- [ ] Go to Info tab
- [ ] NSExtension > NSExtensionAttributes > NSExtensionActivationRule
- [ ] Change from String to Dictionary
- [ ] Add: `NSExtensionActivationSupportsWebURLWithMaxCount` = 1

### 8. Add URL Scheme
- [ ] Select Stash target (main app)
- [ ] Go to Info tab
- [ ] Add URL types > Item 0:
  - URL Schemes: `stash`
  - Identifier: `com.kitkennedy.stash`

### 9. Share Config.swift
- [ ] Select `Config.swift` in navigator
- [ ] File Inspector (right panel) > Target Membership
- [ ] ✓ Check both Stash AND StashShareExtension

### 10. Test It!
- [ ] Build and run on device (⌘R)
- [ ] Open Safari
- [ ] Navigate to any webpage
- [ ] Tap Share > Stash
- [ ] Verify app opens with URL filled in!

## Done! 🎉

Your native iOS Stash app is ready. It works on both iPhone and iPad, and you can share from any app.

## Troubleshooting

**Build errors?**
- Product > Clean Build Folder (⇧⌘K)
- Restart Xcode

**Share extension not appearing?**
- Must use real device (not simulator)
- Force quit Safari and reopen

**Can't sign in?**
- Check Config.swift has your Supabase credentials
- Verify internet connection
