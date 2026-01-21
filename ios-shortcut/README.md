# Stash iOS Shortcut

Save pages to Stash from your iPhone's share sheet.

Notes!
1 Some. of the details here are wrong, look at ![alt text](shortcut_setup_kitiphone.PNG) in this dir for how it's supposed to be setup. The precise headers and reqquest details are correct though.
2. This shortcut didn't work for me, because it doesn't have proper authentication. This only really works in single-user mode, which by default doesn't work in this repo because of how the row-level permissions were configured. So this approach doesn't work as-is.

## Setup

1. Open the Shortcuts app on your iPhone
2. Tap + to create a new shortcut
3. Add these actions:

### Action 1: Receive input
- Type: **Receive** what's passed to the shortcut
- Accept: **URLs** and **Safari web pages**

### Action 2: Get URL
- **Get URLs from** Shortcut Input

### Action 3: Get contents of URL (this saves to Stash)
- URL: `https://YOUR_PROJECT_ID.supabase.co/rest/v1/saves`
- Method: **POST**
- Headers:
  - `apikey`: `YOUR_SUPABASE_ANON_KEY`
  - `Content-Type`: `application/json`
  - `Prefer`: `return=minimal`
- Request Body: **JSON**
  ```
  {
    "user_id": "YOUR_USER_ID",
    "url": [URLs variable],
    "title": "Saved from iPhone",
    "site_name": "",
    "source": "ios-shortcut"
  }
  ```

### Action 4: Show notification
- "Saved to Stash!"

## Add to Share Sheet

1. Tap the shortcut name at the top
2. Tap the (i) info icon
3. Enable "Show in Share Sheet"
4. Name it "Save to Stash"

Now when you're in Safari (or any app), tap Share → Save to Stash!
