import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  RefreshControl,
  Alert,
  Linking,
} from 'react-native';
import * as ExpoLinking from 'expo-linking';
import { useAuth } from '../lib/AuthContext';
import { getRecentSaves, getFolders, savePage, Save, Folder } from '../lib/supabase';
import SaveItem from '../components/SaveItem';
import FolderSelector from '../components/FolderSelector';

export default function HomeScreen() {
  const { user, signOut } = useAuth();
  const [saves, setSaves] = useState<Save[]>([]);
  const [folders, setFolders] = useState<Folder[]>([]);
  const [selectedFolder, setSelectedFolder] = useState<Folder | null>(null);
  const [url, setUrl] = useState('');
  const [title, setTitle] = useState('');
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = useCallback(async () => {
    try {
      const [savesData, foldersData] = await Promise.all([
        getRecentSaves(20),
        getFolders(),
      ]);
      setSaves(savesData);
      setFolders(foldersData);
    } catch (error: any) {
      console.error('Error loading data:', error);
      Alert.alert('Error', 'Failed to load data: ' + error.message);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Handle deep links from Share Extension
  useEffect(() => {
    const handleDeepLink = (event: { url: string }) => {
      const { queryParams } = ExpoLinking.parse(event.url);
      if (queryParams?.url && queryParams?.title) {
        setUrl(decodeURIComponent(queryParams.url as string));
        setTitle(decodeURIComponent(queryParams.title as string));
      }
    };

    // Get initial URL
    ExpoLinking.getInitialURL().then((url) => {
      if (url) {
        handleDeepLink({ url });
      }
    });

    // Listen for URL changes
    const subscription = ExpoLinking.addEventListener('url', handleDeepLink);

    return () => {
      subscription.remove();
    };
  }, []);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  }, [loadData]);

  const handleSave = async () => {
    if (!url || !title) {
      Alert.alert('Error', 'Please enter both URL and title');
      return;
    }

    setLoading(true);
    try {
      await savePage(url, title, undefined, selectedFolder?.id);
      Alert.alert('Success', 'Page saved!');
      setUrl('');
      setTitle('');
      await loadData();
    } catch (error: any) {
      Alert.alert('Error', 'Failed to save: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error: any) {
      Alert.alert('Error', error.message);
    }
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Stash</Text>
        <View style={styles.headerRight}>
          <Text style={styles.userEmail}>{user?.email}</Text>
          <TouchableOpacity onPress={handleSignOut}>
            <Text style={styles.signOutBtn}>Sign Out</Text>
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* Save Form */}
        <View style={styles.saveForm}>
          <Text style={styles.sectionTitle}>Save a Page</Text>

          <TextInput
            style={styles.input}
            placeholder="URL"
            value={url}
            onChangeText={setUrl}
            autoCapitalize="none"
            keyboardType="url"
          />

          <TextInput
            style={styles.input}
            placeholder="Title"
            value={title}
            onChangeText={setTitle}
          />

          <FolderSelector
            folders={folders}
            selectedFolder={selectedFolder}
            onSelectFolder={setSelectedFolder}
          />

          <TouchableOpacity
            style={[styles.button, styles.primaryButton, loading && styles.buttonDisabled]}
            onPress={handleSave}
            disabled={loading}
          >
            <Text style={styles.buttonText}>
              {loading ? 'Saving...' : 'Save Page'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Recent Saves */}
        <View style={styles.recentSection}>
          <Text style={styles.sectionTitle}>Recent Saves</Text>
          {saves.length === 0 ? (
            <Text style={styles.emptyText}>No saves yet. Save your first page!</Text>
          ) : (
            saves.map((save) => (
              <SaveItem
                key={save.id}
                save={save}
                onPress={() => {
                  if (save.url) {
                    Linking.openURL(save.url);
                  }
                }}
              />
            ))
          )}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    paddingTop: 60,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  title: {
    fontSize: 24,
    fontWeight: '600',
    color: '#6366f1',
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  userEmail: {
    fontSize: 12,
    color: '#6b7280',
  },
  signOutBtn: {
    fontSize: 14,
    color: '#6366f1',
    fontWeight: '500',
  },
  content: {
    flex: 1,
  },
  saveForm: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#6b7280',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 12,
  },
  input: {
    backgroundColor: '#f9fafb',
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 12,
  },
  button: {
    padding: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 8,
  },
  primaryButton: {
    backgroundColor: '#6366f1',
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '500',
  },
  recentSection: {
    padding: 16,
  },
  emptyText: {
    color: '#9ca3af',
    textAlign: 'center',
    padding: 20,
    fontSize: 14,
  },
});
