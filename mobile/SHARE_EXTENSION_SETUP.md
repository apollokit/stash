# iOS Share Extension Setup Guide

This guide will help you build the Stash iOS app with Safari Share Extension functionality.

## Prerequisites

- Mac with Xcode installed
- Apple Developer Account (for testing on real devices)
- iOS device (Share Extensions don't work in simulator)

## Quick Start for Testing

The easiest way to test the app on your iPhone/iPad:

### Option 1: Expo Go (Basic Testing - No Share Extension)

```bash
cd mobile
npm start
```

Then scan the QR code with your iPhone camera. This works for basic app testing but **Share Extension will not work**.

### Option 2: Development Build (Full Features Including Share Extension)

This is required to test the Share Extension on your device.

```bash
cd mobile

# Install Expo CLI globally if you haven't
npm install -g expo-cli eas-cli

# Login to Expo
eas login

# Build a development build for your device
eas build --profile development --platform ios

# Or build locally (requires Xcode)
npx expo prebuild
npx expo run:ios --device
```

## Detailed Setup for Share Extension

### Step 1: Generate Native iOS Project

```bash
cd mobile
npx expo prebuild
```

This creates the `ios/` directory with native Xcode project files.

### Step 2: Add Share Extension Target in Xcode

1. Open the project in Xcode:
   ```bash
   open ios/Stash.xcworkspace
   ```

2. In Xcode, click on the project in the left sidebar

3. Click the "+" button at the bottom of the targets list

4. Choose "Share Extension" template

5. Name it "StashShareExtension"

6. Set the bundle identifier to: `com.kitkennedy.stash.ShareExtension`
   (Or use your own bundle ID if you changed it: `<your-main-bundle-id>.ShareExtension`)

7. Click Finish

### Step 3: Replace Share Extension Files

1. In Xcode, navigate to the `StashShareExtension` folder in the project navigator (left sidebar)

2. Delete the default `ShareViewController.swift` and `MainInterface.storyboard` files

3. Copy the files from your project:
   - Copy `ios-share-extension/ShareViewController.swift` to the `StashShareExtension` folder
   - Copy `ios-share-extension/Info.plist` to replace the extension's Info.plist

4. Verify the file setup:
   - Select `ShareViewController.swift` in Xcode
   - Open the File Inspector panel on the right (click the folder icon if not visible)
   - Under "Target Membership", verify that:
     - ✓ "StashShareExtension" is checked
     - ✗ "Stash" (main app) is NOT checked
   - The file should compile without errors (no red marks)

### Step 4: Configure App Groups (for data sharing)

Both the main app and the Share Extension need to share data using App Groups.

1. In Xcode, select the main app target

2. Go to "Signing & Capabilities" tab

3. Click "+ Capability" and add "App Groups"

4. Create a new app group: `group.com.kitkennedy.stash`
   (Use the same format as your bundle ID: `group.<your-bundle-id>`)

5. Repeat steps 1-4 for the Share Extension target (use the same app group name)

### Step 5: Build and Run

1. Connect your iPhone/iPad via USB

2. Select your device in Xcode

3. Click the Run button (or press Cmd+R)

4. The app will install on your device

## Testing the Share Extension

1. Open Safari on your iOS device

2. Navigate to any webpage

3. Tap the Share button (square with arrow pointing up)

4. Scroll down in the share sheet until you see "Stash"

5. Tap "Stash" - the main app will open with the URL and title pre-filled

6. Tap "Save Page" to save it to your Stash

## Troubleshooting

### Share Extension doesn't appear in Safari

- Make sure you built and ran the app from Xcode (not Expo Go)
- Share Extensions only work on real devices, not in simulator
- Try force-quitting Safari and reopening it
- Restart your device

### "Stash" appears but tapping it does nothing

- Check that the URL scheme is configured correctly in app.json
- Make sure both app and extension are signed with the same team
- Check Xcode console for error messages

### Deep link not working

- Verify the URL scheme "stash" is registered in app.json
- Check that the ShareViewController is creating the deep link correctly
- Look for errors in the Xcode console

## Alternative: Using EAS Build

If you prefer not to use Xcode directly:

```bash
# Install EAS CLI
npm install -g eas-cli

# Login
eas login

# Configure the project
eas build:configure

# Build for iOS
eas build --platform ios --profile development

# Install on your device
# After build completes, download the .ipa file and install via Xcode or TestFlight
```

## Publishing to TestFlight / App Store

1. Complete all the steps above

2. Set up your app in App Store Connect

3. Build for release:
   ```bash
   eas build --platform ios --profile production
   ```

4. Submit to App Store:
   ```bash
   eas submit --platform ios
   ```

## Notes

- The Share Extension bundle identifier must be: `<main-bundle-id>.ShareExtension`
- For production, you'll need to update the app signing with your Apple Developer account
- App Groups are required for the extension to share authentication state with the main app
- The extension has limited memory - avoid loading large files or images

## Support

If you run into issues, check:
- Xcode build logs
- Device console logs (Window > Devices and Simulators in Xcode)
- Expo documentation: https://docs.expo.dev
