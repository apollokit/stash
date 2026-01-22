# Share Extension Setup

After the main app works, add Safari sharing capability.

## Step 1: Add Share Extension Target

1. In Xcode, select your project in the navigator
2. Click the **+** button at the bottom of the TARGETS list
3. Choose **iOS > Share Extension**
4. Settings:
   - Product Name: **StashShareExtension**
   - Language: **Swift**
   - Project: Stash
   - Embed in Application: Stash
5. Click **Finish**
6. Click **Activate** when asked about the scheme

## Step 2: Replace Share Extension Code

1. In the navigator, expand **StashShareExtension**
2. Delete these files (Move to Trash):
   - `ShareViewController.swift` (we'll replace it)
   - `MainInterface.storyboard` (not needed)

3. Add the new `ShareViewController.swift`:
   - Right-click **StashShareExtension** folder
   - New File > Swift File
   - Name it `ShareViewController.swift`
   - Copy the code from `ShareViewController.swift` in this directory

## Step 3: Update Info.plist

1. Select **StashShareExtension** target
2. Go to **Info** tab
3. Expand **NSExtension > NSExtensionAttributes**
4. Change **NSExtensionActivationRule** from `String` to `Dictionary`
5. Add inside the dictionary:
   - Key: `NSExtensionActivationSupportsWebURLWithMaxCount`
   - Type: Number
   - Value: `1`

## Step 4: Add URL Scheme to Main App

1. Select the **Stash** target (main app)
2. Go to **Info** tab
3. Add a new row:
   - Key: `URL types` (if not exists)
   - Expand it and add item 0:
     - URL Schemes: (add item 0): `stash`
     - Identifier: `com.kitkennedy.StashApp`

## Step 5: Share Config.swift

The Share Extension needs access to your Supabase config:

1. Select `Config.swift` in the main app
2. In File Inspector (right panel), under **Target Membership**:
   - ✓ Stash (already checked)
   - ✓ StashShareExtension (check this too)

## Step 6: Build and Run

1. Select the **Stash** scheme (not StashShareExtension)
2. Run on your device (Command+R)
3. Open Safari on your device
4. Navigate to any webpage
5. Tap Share button
6. Scroll down and tap **Stash**
7. The main app opens with URL pre-filled!

## How It Works

1. User shares from Safari
2. Share Extension receives the URL and title
3. Extension creates a deep link: `stash://save?url=...&title=...`
4. iOS opens the main Stash app
5. App parses the deep link and pre-fills the save form

No manual copying needed - everything is in git!
