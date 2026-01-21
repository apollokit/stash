import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as SecureStore from 'expo-secure-store';
import { CONFIG } from '../config';

// Custom storage implementation using SecureStore for tokens
// and AsyncStorage for other data
const ExpoSecureStoreAdapter = {
  getItem: async (key: string) => {
    // Use SecureStore for auth tokens, AsyncStorage for everything else
    if (key.includes('token') || key.includes('auth')) {
      return SecureStore.getItemAsync(key);
    }
    return AsyncStorage.getItem(key);
  },
  setItem: async (key: string, value: string) => {
    if (key.includes('token') || key.includes('auth')) {
      return SecureStore.setItemAsync(key, value);
    }
    return AsyncStorage.setItem(key, value);
  },
  removeItem: async (key: string) => {
    if (key.includes('token') || key.includes('auth')) {
      return SecureStore.deleteItemAsync(key);
    }
    return AsyncStorage.removeItem(key);
  },
};

export const supabase = createClient(
  CONFIG.SUPABASE_URL,
  CONFIG.SUPABASE_ANON_KEY,
  {
    auth: {
      storage: ExpoSecureStoreAdapter as any,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  }
);

// Database helpers
export interface Save {
  id: string;
  user_id: string;
  url: string;
  title: string;
  content?: string;
  excerpt?: string;
  highlight?: string;
  site_name?: string;
  author?: string;
  published_at?: string;
  image_url?: string;
  folder_id?: string;
  source: string;
  created_at: string;
  updated_at: string;
}

export interface Folder {
  id: string;
  user_id: string;
  name: string;
  color: string;
  created_at: string;
  updated_at: string;
}

export async function getRecentSaves(limit = 10): Promise<Save[]> {
  const { data, error } = await supabase
    .from('saves')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) throw error;
  return data || [];
}

export async function getFolders(): Promise<Folder[]> {
  const { data, error } = await supabase
    .from('folders')
    .select('*')
    .order('name', { ascending: true });

  if (error) throw error;
  return data || [];
}

export async function savePage(
  url: string,
  title: string,
  content?: string,
  folderId?: string
): Promise<Save> {
  // Get the current user
  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) {
    throw new Error('Not authenticated');
  }

  const saveData: any = {
    user_id: user.id,
    url,
    title,
    content,
    site_name: new URL(url).hostname.replace('www.', ''),
    source: 'mobile',
  };

  if (folderId) {
    saveData.folder_id = folderId;
  }

  const { data, error } = await supabase
    .from('saves')
    .insert(saveData)
    .select()
    .single();

  if (error) throw error;
  return data;
}
