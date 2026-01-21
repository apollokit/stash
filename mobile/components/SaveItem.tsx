import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Save } from '../lib/supabase';

interface SaveItemProps {
  save: Save;
  onPress: () => void;
}

export default function SaveItem({ save, onPress }: SaveItemProps) {
  const isHighlight = !!save.highlight;
  const displayTitle = save.title || save.highlight?.substring(0, 50) || 'Untitled';
  const date = new Date(save.created_at).toLocaleDateString();

  return (
    <TouchableOpacity style={styles.container} onPress={onPress}>
      <View style={[styles.icon, isHighlight && styles.iconHighlight]}>
        <Text style={styles.iconText}>{isHighlight ? '✨' : '📄'}</Text>
      </View>
      <View style={styles.content}>
        <Text style={styles.title} numberOfLines={1}>
          {displayTitle}
        </Text>
        <Text style={styles.meta}>
          {save.site_name || ''} · {date}
        </Text>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    gap: 10,
    padding: 12,
    backgroundColor: '#f9fafb',
    borderRadius: 8,
    marginBottom: 8,
  },
  icon: {
    width: 40,
    height: 40,
    backgroundColor: '#e5e7eb',
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconHighlight: {
    backgroundColor: '#fef3c7',
  },
  iconText: {
    fontSize: 18,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
  },
  title: {
    fontSize: 14,
    fontWeight: '500',
    color: '#1f2937',
    marginBottom: 2,
  },
  meta: {
    fontSize: 12,
    color: '#6b7280',
  },
});
