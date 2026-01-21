# Stash Mobile App

iOS/iPad app for Stash - save and organize web content from Safari.

## Features

- Save web pages from Safari using Share Extension
- Organize saves into folders
- View recent saves
- Sync with web app via Supabase

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- iOS device or simulator
- Xcode (for iOS development)
- Expo CLI

### Installation

```bash
cd mobile
npm install
```

### Running the App

**On iOS Simulator:**
```bash
npm run ios
```

**On Your iPhone/iPad:**

1. Install Expo Go app from the App Store
2. Run: `npm start`
3. Scan the QR code with your camera app

**For Production Build:**

To test the Share Extension on a real device, you'll need to create a development build:

```bash
npx expo prebuild
npx expo run:ios
```

## Share Extension Setup

The Share Extension allows you to save webpages directly from Safari's share sheet.

### Building with Share Extension

1. Generate native iOS files:
   ```bash
   npx expo prebuild
   ```

2. Open the project in Xcode:
   ```bash
   open ios/mobile.xcworkspace
   ```

3. The Share Extension target will be automatically configured

4. Build and run on a real device (Share Extensions don't work in simulator)

### Testing the Share Extension

1. Open Safari on your iOS device
2. Navigate to a webpage
3. Tap the Share button
4. Scroll down and tap "Stash" in the share sheet
5. The page will be saved to your Stash account

## Project Structure

```
mobile/
├── screens/
│   ├── AuthScreen.tsx      # Sign in/up screen
│   └── HomeScreen.tsx      # Main app screen
├── components/
│   ├── SaveItem.tsx        # Save card component
│   └── FolderSelector.tsx  # Folder selection modal
├── lib/
│   ├── supabase.ts         # Supabase client & helpers
│   └── AuthContext.tsx     # Authentication context
├── config.ts               # Configuration
└── App.tsx                 # Main app entry point
```

## Configuration

Update `config.ts` with your Supabase credentials:

```typescript
export const CONFIG = {
  SUPABASE_URL: 'your-supabase-url',
  SUPABASE_ANON_KEY: 'your-supabase-anon-key',
};
```

## Deployment

### TestFlight (Beta Testing)

1. Create an app in App Store Connect
2. Build and upload:
   ```bash
   eas build --platform ios
   eas submit --platform ios
   ```

### App Store

Follow the same process as TestFlight, then submit for App Store review.

## Notes

- The Share Extension requires a development or production build (not Expo Go)
- Share Extensions only work on physical devices, not in the simulator
- You'll need an Apple Developer account for TestFlight and App Store deployment
