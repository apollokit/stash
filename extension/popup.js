// Popup script
document.addEventListener('DOMContentLoaded', async () => {
  const authView = document.getElementById('auth-view');
  const mainView = document.getElementById('main-view');
  const authForm = document.getElementById('auth-form');
  const authError = document.getElementById('auth-error');
  const signinBtn = document.getElementById('signin-btn');
  const signupBtn = document.getElementById('signup-btn');
  const signoutBtn = document.getElementById('signout-btn');
  const savePageBtn = document.getElementById('save-page-btn');
  const savesList = document.getElementById('saves-list');
  const openAppLink = document.getElementById('open-app-link');
  const saveToFolderBtn = document.getElementById('save-to-folder-btn');
  const folderDropdown = document.getElementById('folder-dropdown');
  const folderList = document.getElementById('folder-list');
  const folderBtnText = document.getElementById('folder-btn-text');

  let folders = [];
  let selectedFolder = null;

  // Check if user is authenticated
  const response = await chrome.runtime.sendMessage({ action: 'getUser' });
  if (response && response.user) {
    showMainView(response.user);
    loadRecentSaves();
  } else {
    showAuthView();
  }

  function showAuthView() {
    authView.classList.remove('hidden');
    mainView.classList.add('hidden');
  }

  function showMainView(user) {
    authView.classList.add('hidden');
    mainView.classList.remove('hidden');

    // Display user email if available
    if (user && user.email) {
      const userEmail = document.createElement('span');
      userEmail.className = 'user-email';
      userEmail.textContent = user.email;
      signoutBtn.parentNode.insertBefore(userEmail, signoutBtn);
    }

    // Load folders and last used folder
    loadFolders();
  }

  // Sign in
  authForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    signinBtn.disabled = true;
    signinBtn.textContent = 'Signing in...';
    authError.textContent = '';

    const response = await chrome.runtime.sendMessage({
      action: 'signIn',
      email,
      password,
    });

    if (response.success) {
      showMainView(response.user);
      loadRecentSaves();
    } else {
      authError.textContent = response.error;
    }

    signinBtn.disabled = false;
    signinBtn.textContent = 'Sign In';
  });

  // Sign up
  signupBtn.addEventListener('click', async () => {
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    if (!email || !password) {
      authError.textContent = 'Please enter email and password';
      return;
    }

    signupBtn.disabled = true;
    signupBtn.textContent = 'Signing up...';
    authError.textContent = '';

    // For signup, we'll redirect to the web app
    // Supabase email confirmation is required by default
    const signupUrl = `${CONFIG.WEB_APP_URL}/signup`;
    chrome.tabs.create({ url: signupUrl });

    signupBtn.disabled = false;
    signupBtn.textContent = 'Sign Up';
  });

  // Sign out
  signoutBtn.addEventListener('click', async () => {
    await chrome.runtime.sendMessage({ action: 'signOut' });
    showAuthView();
  });

  // Save page
  savePageBtn.addEventListener('click', async () => {
    savePageBtn.disabled = true;
    savePageBtn.innerHTML = `
      <svg class="spinning" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M21 12a9 9 0 1 1-6.219-8.56"></path>
      </svg>
      Saving...
    `;

    // Pass folder ID if a folder is selected
    const message = { action: 'savePage' };
    if (selectedFolder) {
      message.folderId = selectedFolder.id;
    }
    await chrome.runtime.sendMessage(message);

    savePageBtn.disabled = false;
    savePageBtn.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="20 6 9 17 4 12"></polyline>
      </svg>
      Saved!
    `;

    setTimeout(() => {
      savePageBtn.innerHTML = `
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
          <polyline points="17 21 17 13 7 13 7 21"></polyline>
          <polyline points="7 3 7 8 15 8"></polyline>
        </svg>
        Save This Page
      `;
      loadRecentSaves();
    }, 1500);
  });

  // Load recent saves
  async function loadRecentSaves() {
    const response = await chrome.runtime.sendMessage({ action: 'getRecentSaves' });

    if (!response.success || !response.saves?.length) {
      savesList.innerHTML = '<p class="empty">No saves yet. Save your first page!</p>';
      return;
    }

    savesList.innerHTML = response.saves.map(save => {
      const isHighlight = !!save.highlight;
      const title = save.title || save.highlight?.substring(0, 50) || 'Untitled';
      const date = new Date(save.created_at).toLocaleDateString();

      return `
        <div class="save-item" data-url="${save.url}">
          <div class="icon ${isHighlight ? 'highlight' : ''}">
            ${isHighlight ? '✨' : '📄'}
          </div>
          <div class="content">
            <div class="title">${escapeHtml(title)}</div>
            <div class="meta">${save.site_name || ''} · ${date}</div>
          </div>
        </div>
      `;
    }).join('');

    // Add click handlers
    savesList.querySelectorAll('.save-item').forEach(item => {
      item.addEventListener('click', () => {
        const url = item.dataset.url;
        if (url) chrome.tabs.create({ url });
      });
    });
  }

  // Load folders
  async function loadFolders() {
    const response = await chrome.runtime.sendMessage({ action: 'getFolders' });

    if (!response.success || !response.folders?.length) {
      folders = [];
      renderFolderList(); // Update UI even when there are no folders
      return;
    }

    folders = response.folders;

    renderFolderList();
  }

  // Render folder dropdown list
  function renderFolderList() {
    // Always show "No folder" option first
    let html = `
      <div class="folder-item no-folder-item" data-folder-id="">
        <div class="folder-color" style="background-color: #6b7280"></div>
        <div class="folder-name">No folder</div>
      </div>
    `;

    if (folders.length) {
      html += folders.map(folder => {
        // Ensure color has # prefix for CSS
        let color = folder.color || '#6b7280';
        if (color && !color.startsWith('#')) {
          color = '#' + color;
        }
        return `
          <div class="folder-item" data-folder-id="${folder.id}">
            <div class="folder-color" style="background-color: ${color}"></div>
            <div class="folder-name">${escapeHtml(folder.name)}</div>
          </div>
        `;
      }).join('');
    }

    folderList.innerHTML = html;

    // Add click handlers
    folderList.querySelectorAll('.folder-item').forEach(item => {
      item.addEventListener('click', () => {
        const folderId = item.dataset.folderId;
        if (folderId) {
          selectedFolder = folders.find(f => f.id === folderId);
        } else {
          // "No folder" selected
          selectedFolder = null;
        }
        updateFolderButtonText();
        updateFolderButtonStyle();
        folderDropdown.classList.add('hidden');
      });
    });
  }

  // Update folder button text
  function updateFolderButtonText() {
    if (selectedFolder) {
      // Ensure color has # prefix for CSS
      let color = selectedFolder.color || '#6b7280';
      if (color && !color.startsWith('#')) {
        color = '#' + color;
      }
      folderBtnText.innerHTML = `<span style="color: ${color}">●</span> Save to "${escapeHtml(selectedFolder.name)}"`;
    } else {
      folderBtnText.innerHTML = 'Select folder';
    }
  }

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (!folderDropdown.contains(e.target) &&
        !saveToFolderBtn.contains(e.target)) {
      folderDropdown.classList.add('hidden');
    }
  });

  // Toggle folder dropdown (folder button just selects folder, doesn't save)
  saveToFolderBtn.addEventListener('click', () => {
    folderDropdown.classList.toggle('hidden');
  });

  // Update folder button style based on selection
  function updateFolderButtonStyle() {
    if (selectedFolder) {
      saveToFolderBtn.classList.remove('secondary');
      saveToFolderBtn.classList.add('primary');
    } else {
      saveToFolderBtn.classList.remove('primary');
      saveToFolderBtn.classList.add('secondary');
    }
  }

  // Open web app
  openAppLink.addEventListener('click', (e) => {
    e.preventDefault();
    chrome.tabs.create({ url: CONFIG.WEB_APP_URL });
  });

  // Helper
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

});

// Add spinning animation
const style = document.createElement('style');
style.textContent = `
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
  .spinning {
    animation: spin 1s linear infinite;
  }
`;
document.head.appendChild(style);