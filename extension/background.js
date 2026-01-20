// Background service worker
// Handles context menus and saving

importScripts('config.js', 'supabase.js');

let supabase = null;

// Initialize on startup
chrome.runtime.onInstalled.addListener(() => {
  initSupabase();
  setupContextMenu();
});

chrome.runtime.onStartup.addListener(() => {
  initSupabase();
});

async function initSupabase() {
  supabase = new SupabaseClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);
  await supabase.init();
}

// Context menu for "Save highlight to Stash"
function setupContextMenu() {
  chrome.contextMenus.removeAll(() => {
    chrome.contextMenus.create({
      id: 'save-highlight',
      title: 'Save highlight to Stash',
      contexts: ['selection'],
    });

    chrome.contextMenus.create({
      id: 'save-page',
      title: 'Save page to Stash',
      contexts: ['page'],
    });
  });
}

// Handle context menu clicks
chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (!supabase) await initSupabase();

  if (info.menuItemId === 'save-highlight') {
    await saveHighlight(tab, info.selectionText);
  } else if (info.menuItemId === 'save-page') {
    await savePage(tab);
  }
});

// Save highlighted text
async function saveHighlight(tab, selectionText) {
  try {
    await supabase.insert('saves', {
      user_id: CONFIG.USER_ID,
      url: tab.url,
      title: tab.title,
      highlight: selectionText,
      site_name: new URL(tab.url).hostname.replace('www.', ''),
      source: 'extension',
    });

    chrome.tabs.sendMessage(tab.id, {
      action: 'showToast',
      message: 'Highlight saved!',
    });
  } catch (err) {
    console.error('Save highlight failed:', err);
    chrome.tabs.sendMessage(tab.id, {
      action: 'showToast',
      message: 'Failed to save: ' + err.message,
      isError: true,
    });
  }
}

// Save full page
async function savePage(tab, folderId = null) {
  try {
    console.log('savePage called for:', tab.url, 'folder:', folderId);
    let article;

    // Extract from current page - inject content script first if needed
    console.log('Extracting article...');

    try {
      article = await chrome.tabs.sendMessage(tab.id, { action: 'extractArticle' });
    } catch (e) {
      // Content script not loaded, inject it first
      console.log('Content script not loaded, injecting...');
      await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        files: ['Readability.js', 'content.js']
      });
      // Wait a moment for script to initialize
      await new Promise(r => setTimeout(r, 100));
      article = await chrome.tabs.sendMessage(tab.id, { action: 'extractArticle' });
    }

    console.log('Article extracted:', article?.title, 'content length:', article?.content?.length);

    if (!article) {
      throw new Error('Failed to extract article content');
    }

    console.log('Inserting into Supabase...');
    const saveData = {
      user_id: CONFIG.USER_ID,
      url: tab.url,
      title: article.title,
      content: article.content,
      excerpt: article.excerpt,
      site_name: article.siteName,
      author: article.author,
      published_at: article.publishedTime,
      image_url: article.imageUrl,
      source: 'extension',
    };

    // Add folder_id if provided
    if (folderId) {
      saveData.folder_id = folderId;
    }

    const result = await supabase.insert('saves', saveData);
    console.log('Insert result:', result);

    chrome.tabs.sendMessage(tab.id, {
      action: 'showToast',
      message: 'Page saved!',
    });
  } catch (err) {
    console.error('Save page failed:', err);
    chrome.tabs.sendMessage(tab.id, {
      action: 'showToast',
      message: 'Failed to save: ' + err.message,
      isError: true,
    });
  }
}

// Handle messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'savePage') {
    chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
      if (tabs[0]) {
        await savePage(tabs[0], request.folderId);
        sendResponse({ success: true });
      }
    });
    return true;
  }

  if (request.action === 'getUser') {
    (async () => {
      if (!supabase) await initSupabase();
      const user = await supabase.getUser();
      sendResponse({ user });
    })();
    return true;
  }

  if (request.action === 'signIn') {
    (async () => {
      if (!supabase) await initSupabase();
      try {
        await supabase.signIn(request.email, request.password);
        const user = await supabase.getUser();
        sendResponse({ success: true, user });
      } catch (err) {
        sendResponse({ success: false, error: err.message });
      }
    })();
    return true;
  }

  if (request.action === 'signOut') {
    (async () => {
      if (!supabase) await initSupabase();
      await supabase.signOut();
      sendResponse({ success: true });
    })();
    return true;
  }

  if (request.action === 'getRecentSaves') {
    (async () => {
      if (!supabase) await initSupabase();
      try {
        const saves = await supabase.select('saves', {
          order: 'created_at.desc',
          limit: 10,
        });
        sendResponse({ success: true, saves });
      } catch (err) {
        sendResponse({ success: false, error: err.message });
      }
    })();
    return true;
  }

  if (request.action === 'getFolders') {
    (async () => {
      // console.log('getFolders: Starting request');
      if (!supabase) await initSupabase();
      try {
        // Get the current user
        // console.log('getFolders: Getting user...');
        const user = await supabase.getUser();
        // console.log('getFolders: User result:', user);

        if (!user) {
          // console.log('getFolders: No user found');
          sendResponse({ success: false, error: 'Not authenticated' });
          return;
        }

        // console.log('getFolders: Fetching folders for user:', user.id);
        const folders = await supabase.select('folders', {
          filters: { user_id: user.id },
          order: 'name.asc',
        });
        // console.log('getFolders: Folders result:', folders);
        sendResponse({ success: true, folders });
      } catch (err) {
        // console.error('getFolders: Error:', err);
        sendResponse({ success: false, error: err.message });
      }
    })();
    return true;
  }
});
