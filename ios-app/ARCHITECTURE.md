# Stash iOS Architecture

## App Flow

```
┌─────────────┐
│   Stash     │  Main App Entry Point
│   App.swift │  - Checks authentication
└──────┬──────┘  - Shows Auth or Home view
       │
       ├─── Not Authenticated ──→ ┌──────────────┐
       │                          │  AuthView    │
       │                          │  - Sign in   │
       │                          │  - Sign up   │
       │                          └──────────────┘
       │
       └─── Authenticated ──────→ ┌──────────────┐
                                  │  HomeView    │
                                  │  - Save form │
                                  │  - Folders   │
                                  │  - Recent    │
                                  └──────────────┘
```

## Data Flow

```
┌──────────────┐
│  SwiftUI     │  Views (AuthView, HomeView, etc.)
│  Views       │  - Display UI
└──────┬───────┘  - Handle user input
       │
       ↓
┌──────────────┐
│  Supabase    │  Service Layer (SupabaseService.swift)
│  Service     │  - API calls
└──────┬───────┘  - Authentication
       │          - State management (@Published)
       ↓
┌──────────────┐
│  Supabase    │  Supabase Swift SDK
│  Client      │  - HTTP requests
└──────┬───────┘  - Session management
       │
       ↓
┌──────────────┐
│  Supabase    │  Your Database
│  Database    │  - saves table
└──────────────┘  - folders table
                  - RLS policies
```

## Share Extension Flow

```
Safari/Apps
     │
     │ User taps Share → Stash
     ↓
┌─────────────────────┐
│ ShareView           │  Share Extension
│ Controller.swift    │  - Receives URL + title
└──────────┬──────────┘  - Creates deep link
           │
           │ Opens: stash://save?url=...&title=...
           ↓
┌──────────────────────┐
│ Main Stash App       │  Main App
│ (HomeView)           │  - Receives deep link
└──────────┬───────────┘  - Pre-fills form
           │
           │ User taps "Save Page"
           ↓
┌──────────────────────┐
│ Supabase Database    │  Saved!
└──────────────────────┘
```

## File Structure

```
ios-app/
├── Stash.xcodeproj/           # Xcode project (version controlled)
│
├── Stash/Stash/               # Main app target
│   ├── StashApp.swift         # Entry point
│   │   └─→ Decides: AuthView or HomeView
│   │
│   ├── Models.swift           # Data structures
│   │   ├── Save              # Save model
│   │   ├── Folder            # Folder model
│   │   └── CreateSaveRequest # API request model
│   │
│   ├── SupabaseService.swift # API service (@MainActor)
│   │   ├── @Published currentUser
│   │   ├── @Published isAuthenticated
│   │   ├── signIn/signUp/signOut
│   │   ├── getRecentSaves()
│   │   ├── createSave()
│   │   └── getFolders()
│   │
│   ├── AuthView.swift        # Login screen
│   │   └─→ Calls: supabase.signIn/signUp
│   │
│   ├── HomeView.swift        # Main screen
│   │   ├─→ Save form
│   │   ├─→ Folder selector
│   │   ├─→ Recent saves list
│   │   └─→ Deep link handler
│   │
│   ├── SaveItemRow.swift     # List item component
│   │   └─→ Displays one save
│   │
│   ├── FolderSelector.swift  # Folder picker modal
│   │   └─→ Folder selection
│   │
│   └── Config.swift          # Supabase credentials
│
└── Stash/StashShareExtension/ # Share Extension target
    ├── ShareViewController.swift  # Share Extension
    │   └─→ Receives URL → Opens main app
    └── Info.plist            # Extension configuration
```

## State Management

Uses SwiftUI's built-in state management:

- **@StateObject**: SupabaseService (app-wide singleton)
- **@EnvironmentObject**: Injected into views
- **@Published**: Properties that trigger view updates
- **@State**: Local view state
- **@Binding**: Two-way bindings for child views

## Key Patterns

### 1. Service Layer Pattern
All API calls go through SupabaseService.swift - views never call Supabase directly.

### 2. Model-View Pattern
- Models (Save, Folder) are pure data structures
- Views consume models and call service methods
- No business logic in views

### 3. Async/Await
All async operations use Swift's modern concurrency:
```swift
Task {
    let saves = try await supabase.getRecentSaves()
}
```

### 4. SwiftUI Lifecycle
- `.task {}` - Run async code when view appears
- `.onOpenURL {}` - Handle deep links
- `.refreshable {}` - Pull to refresh

## Dependencies

Only one external dependency:
- **Supabase Swift SDK** (via Swift Package Manager)

Everything else is pure SwiftUI and Foundation.

## Testing Strategy

1. **Main App Testing**
   - Run on simulator or device
   - Test auth flow
   - Test save creation
   - Test folder selection

2. **Share Extension Testing**
   - Must use real device
   - Test from Safari
   - Test from other apps (News, Messages)
   - Verify deep link handling

3. **iPad Testing**
   - Same codebase works automatically
   - SwiftUI handles layout adaptation
   - Test on iPad simulator or device

## Security

- Supabase RLS policies enforced server-side
- Authentication tokens stored securely by Supabase SDK
- No sensitive data in code (except Config.swift)
- Config.swift should be in .gitignore for production
  (Currently tracked for convenience in your private repo)

## Performance

- Minimal dependencies = fast startup
- Native Swift = excellent performance
- SwiftUI = efficient rendering
- No JavaScript bridge overhead
- Small app size (~5-10 MB)

## Deployment

For TestFlight/App Store:
1. Archive build in Xcode (Product > Archive)
2. Upload to App Store Connect
3. Submit for review

For development:
- Open Stash.xcodeproj in Xcode
- Press ⌘R to build and run
- Entire project tracked in git
- Clone and run on any Mac - no setup required
