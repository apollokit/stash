// Minimal Supabase client for Chrome extension
class SupabaseClient {
  constructor(url, anonKey) {
    this.url = url;
    this.anonKey = anonKey;
    this.accessToken = null;
    this.refreshToken = null;
    this.expiresAt = null;
  }

  async init() {
    const stored = await chrome.storage.local.get(['stash_session']);
    if (stored.stash_session) {
      this.accessToken = stored.stash_session.access_token;
      this.refreshToken = stored.stash_session.refresh_token;
      this.expiresAt = stored.stash_session.expires_at;

      // Check if token needs refresh (refresh 5 minutes before expiry)
      if (this.isTokenExpired()) {
        await this.refreshSession();
      }
    }
  }

  isTokenExpired() {
    if (!this.expiresAt) return true;
    // Refresh 5 minutes before actual expiry
    const bufferSeconds = 300;
    return Date.now() / 1000 > (this.expiresAt - bufferSeconds);
  }

  async refreshSession() {
    if (!this.refreshToken) {
      this.accessToken = null;
      return false;
    }

    try {
      const res = await fetch(`${this.url}/auth/v1/token?grant_type=refresh_token`, {
        method: 'POST',
        headers: {
          'apikey': this.anonKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ refresh_token: this.refreshToken }),
      });

      if (!res.ok) {
        // Refresh failed, clear session
        await this.signOut();
        return false;
      }

      const data = await res.json();
      this.accessToken = data.access_token;
      this.refreshToken = data.refresh_token;
      this.expiresAt = data.expires_at;
      await chrome.storage.local.set({ stash_session: data });
      return true;
    } catch (e) {
      console.error('Token refresh failed:', e);
      return false;
    }
  }

  async getHeaders() {
    // Auto-refresh token if expired
    if (this.isTokenExpired() && this.refreshToken) {
      await this.refreshSession();
    }

    const h = {
      'apikey': this.anonKey,
      'Content-Type': 'application/json',
    };
    if (this.accessToken) {
      h['Authorization'] = `Bearer ${this.accessToken}`;
    }
    return h;
  }

  // Keep sync version for backwards compatibility, but prefer async
  get headers() {
    const h = {
      'apikey': this.anonKey,
      'Content-Type': 'application/json',
    };
    if (this.accessToken) {
      h['Authorization'] = `Bearer ${this.accessToken}`;
    }
    return h;
  }

  async signIn(email, password) {
    const res = await fetch(`${this.url}/auth/v1/token?grant_type=password`, {
      method: 'POST',
      headers: {
        'apikey': this.anonKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });

    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.error_description || err.msg || 'Sign in failed');
    }

    const data = await res.json();
    this.accessToken = data.access_token;
    this.refreshToken = data.refresh_token;
    this.expiresAt = data.expires_at;
    await chrome.storage.local.set({ stash_session: data });
    return data;
  }

  async signUp(email, password) {
    const res = await fetch(`${this.url}/auth/v1/signup`, {
      method: 'POST',
      headers: {
        'apikey': this.anonKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });

    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.error_description || err.msg || 'Sign up failed');
    }

    return await res.json();
  }

  async signOut() {
    this.accessToken = null;
    this.refreshToken = null;
    this.expiresAt = null;
    await chrome.storage.local.remove(['stash_session']);
  }

  async getUser() {
    if (!this.accessToken && !this.refreshToken) return null;

    // Try to refresh if token is expired
    if (this.isTokenExpired()) {
      const refreshed = await this.refreshSession();
      if (!refreshed) return null;
    }

    const headers = await this.getHeaders();
    const res = await fetch(`${this.url}/auth/v1/user`, { headers });

    if (!res.ok) {
      // If unauthorized, try refreshing once more
      if (res.status === 401 && this.refreshToken) {
        const refreshed = await this.refreshSession();
        if (refreshed) {
          const retryHeaders = await this.getHeaders();
          const retryRes = await fetch(`${this.url}/auth/v1/user`, { headers: retryHeaders });
          if (retryRes.ok) return await retryRes.json();
        }
      }
      return null;
    }
    return await res.json();
  }

  // Database operations
  async insert(table, data) {
    console.log('Supabase insert:', table, 'data keys:', Object.keys(data));
    const headers = await this.getHeaders();
    const res = await fetch(`${this.url}/rest/v1/${table}`, {
      method: 'POST',
      headers: { ...headers, 'Prefer': 'return=representation' },
      body: JSON.stringify(data),
    });

    console.log('Supabase response status:', res.status);

    if (!res.ok) {
      const err = await res.json();
      console.error('Supabase insert error:', err);
      throw new Error(err.message || err.error || 'Insert failed');
    }

    const result = await res.json();
    console.log('Supabase insert success:', result);
    return result;
  }

  async select(table, options = {}) {
    let url = `${this.url}/rest/v1/${table}?select=${options.select || '*'}`;

    if (options.filters) {
      for (const [key, value] of Object.entries(options.filters)) {
        url += `&${key}=eq.${encodeURIComponent(value)}`;
      }
    }

    if (options.order) {
      url += `&order=${options.order}`;
    }

    if (options.limit) {
      url += `&limit=${options.limit}`;
    }

    const headers = await this.getHeaders();
    const res = await fetch(url, { headers });

    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.message || 'Select failed');
    }

    return await res.json();
  }

  async update(table, id, data) {
    const headers = await this.getHeaders();
    const res = await fetch(`${this.url}/rest/v1/${table}?id=eq.${id}`, {
      method: 'PATCH',
      headers: { ...headers, 'Prefer': 'return=representation' },
      body: JSON.stringify(data),
    });

    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.message || 'Update failed');
    }

    return await res.json();
  }

  async delete(table, id) {
    const headers = await this.getHeaders();
    const res = await fetch(`${this.url}/rest/v1/${table}?id=eq.${id}`, {
      method: 'DELETE',
      headers,
    });

    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.message || 'Delete failed');
    }

    return true;
  }
}

// Export for use in extension
if (typeof window !== 'undefined') {
  window.SupabaseClient = SupabaseClient;
}
