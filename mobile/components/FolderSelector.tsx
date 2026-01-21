import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
  ScrollView,
} from 'react-native';
import { Folder } from '../lib/supabase';

interface FolderSelectorProps {
  folders: Folder[];
  selectedFolder: Folder | null;
  onSelectFolder: (folder: Folder | null) => void;
}

export default function FolderSelector({
  folders,
  selectedFolder,
  onSelectFolder,
}: FolderSelectorProps) {
  const [modalVisible, setModalVisible] = useState(false);

  const handleSelect = (folder: Folder | null) => {
    onSelectFolder(folder);
    setModalVisible(false);
  };

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={styles.button}
        onPress={() => setModalVisible(true)}
      >
        <View style={styles.buttonContent}>
          {selectedFolder ? (
            <>
              <View
                style={[styles.folderColor, { backgroundColor: selectedFolder.color }]}
              />
              <Text style={styles.buttonText}>
                Save to "{selectedFolder.name}"
              </Text>
            </>
          ) : (
            <>
              <Text style={styles.buttonText}>📁 Save to folder (optional)</Text>
            </>
          )}
        </View>
      </TouchableOpacity>

      <Modal
        visible={modalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Select Folder</Text>
              <TouchableOpacity onPress={() => setModalVisible(false)}>
                <Text style={styles.closeButton}>✕</Text>
              </TouchableOpacity>
            </View>

            <ScrollView style={styles.folderList}>
              <TouchableOpacity
                style={styles.folderItem}
                onPress={() => handleSelect(null)}
              >
                <Text style={styles.folderName}>No folder</Text>
                {!selectedFolder && <Text style={styles.checkmark}>✓</Text>}
              </TouchableOpacity>

              {folders.map((folder) => (
                <TouchableOpacity
                  key={folder.id}
                  style={styles.folderItem}
                  onPress={() => handleSelect(folder)}
                >
                  <View
                    style={[styles.folderColor, { backgroundColor: folder.color }]}
                  />
                  <Text style={styles.folderName}>{folder.name}</Text>
                  {selectedFolder?.id === folder.id && (
                    <Text style={styles.checkmark}>✓</Text>
                  )}
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 12,
  },
  button: {
    backgroundColor: '#f3f4f6',
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 8,
    padding: 12,
  },
  buttonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  buttonText: {
    fontSize: 16,
    color: '#374151',
  },
  folderColor: {
    width: 12,
    height: 12,
    borderRadius: 3,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#ffffff',
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    maxHeight: '70%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1f2937',
  },
  closeButton: {
    fontSize: 24,
    color: '#6b7280',
  },
  folderList: {
    padding: 8,
  },
  folderItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 12,
    borderRadius: 8,
  },
  folderName: {
    flex: 1,
    fontSize: 16,
    color: '#1f2937',
  },
  checkmark: {
    fontSize: 18,
    color: '#6366f1',
  },
});
