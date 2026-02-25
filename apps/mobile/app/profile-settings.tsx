import { useEffect, useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  StyleSheet,
  Pressable,
  Alert,
  Modal,
  TextInput,
  Image,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { useCountries } from '../hooks/useCountries';
import { useTheme } from '../hooks/useTheme';

import * as ImagePicker from 'expo-image-picker';
import * as ImageManipulator from 'expo-image-manipulator';

type EditField = 'full_name' | 'username';

export default function ProfileSettingsScreen() {
  const router = useRouter();
  const { profile, signOut, updateProfile } = useAuth();

  /* ---------------- Logout ---------------- */

  const handleLogout = async () => {
    try {
      await signOut();
      // Let AuthGate redirect to landing (/)
    } catch {
      Alert.alert('Logout failed', 'Please try again.');
    }
  };

  /* ---------------- Delete Account ---------------- */

  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const handleDeleteAccount = async () => {
    try {
      setDeleting(true);

      const { error } = await supabase.functions.invoke('delete-account', {
        body: {},
      });

      if (error) throw error;

      await signOut();
      await supabase.auth.signOut();
      // Let AuthGate redirect to landing (/)
    } catch (e: any) {
      Alert.alert('Delete failed', e?.message ?? 'Please try again.');
    } finally {
      setDeleting(false);
      setDeleteOpen(false);
    }
  };

  const colors = useTheme();
  const borderColor = colors.border;

  const [isSavingProfile, setIsSavingProfile] = useState(false);
  const [isUploadingAvatar, setIsUploadingAvatar] = useState(false);
  const [avatarMenuOpen, setAvatarMenuOpen] = useState(false);

  /* ---------------- Avatar ---------------- */

  const pickAvatar = async () => {
    try {
      const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (!permission.granted) {
        Alert.alert('Permission required', 'Please allow photo access.');
        return;
      }

      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: true,
        quality: 1,
      });

      if (result.canceled) return;

      setIsUploadingAvatar(true);

      const image = result.assets[0];

      const manipulated = await ImageManipulator.manipulateAsync(
        image.uri,
        [{ resize: { width: 512 } }],
        { compress: 0.7, format: ImageManipulator.SaveFormat.JPEG }
      );

      const response = await fetch(manipulated.uri);
      const blob = await response.blob();

      const fileName = `${profile?.id}-${Date.now()}.jpg`;

      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(fileName, blob, {
          contentType: 'image/jpeg',
          upsert: true,
        });

      if (uploadError) throw uploadError;

      const { data } = supabase.storage.from('avatars').getPublicUrl(fileName);

      await updateProfile({ avatar_url: data.publicUrl });
    } catch (e: any) {
      Alert.alert('Upload failed', e?.message ?? 'Please try again.');
    } finally {
      setIsUploadingAvatar(false);
      setAvatarMenuOpen(false);
    }
  };

  const deleteAvatar = async () => {
    try {
      if (!profile?.avatar_url) return;

      setIsUploadingAvatar(true);

      const fileName = profile.avatar_url.split('/').pop();
      if (fileName) {
        await supabase.storage.from('avatars').remove([fileName]);
      }

      await updateProfile({ avatar_url: null });
    } catch {
      Alert.alert('Error', 'Failed to remove profile photo.');
    } finally {
      setIsUploadingAvatar(false);
      setAvatarMenuOpen(false);
    }
  };

  /* ---------------- Draft State ---------------- */

  const [draftMode, setDraftMode] = useState<string | null>(null);
  const [draftStyle, setDraftStyle] = useState<string | null>(null);
  const [draftNextDestination, setDraftNextDestination] = useState<string | null>(null);
  const [draftLivedCountries, setDraftLivedCountries] = useState<string[]>([]);
  const [draftLanguages, setDraftLanguages] = useState<any[]>([]);

  const { countries } = useCountries();

  /* ---------------- Normalize Array Fields ---------------- */

  const currentMode =
    Array.isArray(profile?.travel_mode) ? profile?.travel_mode?.[0] ?? null : null;

  const currentStyle =
    Array.isArray(profile?.travel_style) ? profile?.travel_style?.[0] ?? null : null;

  useEffect(() => {
    setDraftMode(currentMode);
    setDraftStyle(currentStyle);
    setDraftNextDestination(profile?.next_destination ?? null);

    if (Array.isArray(profile?.languages)) {
      setDraftLanguages(profile.languages);
    } else {
      setDraftLanguages([]);
    }

    if (Array.isArray(profile?.lived_countries)) {
      setDraftLivedCountries(profile.lived_countries);
    } else {
      setDraftLivedCountries([]);
    }
  }, [profile]);

  /* ---------------- Change Detection ---------------- */

  const hasChanges =
    draftMode !== currentMode ||
    draftStyle !== currentStyle ||
    draftNextDestination !== profile?.next_destination ||
    JSON.stringify(draftLanguages) !== JSON.stringify(profile?.languages ?? []) ||
    JSON.stringify(draftLivedCountries) !== JSON.stringify(profile?.lived_countries ?? []);

  /* ---------------- Save ---------------- */

  const saveAll = async () => {
    try {
      setIsSavingProfile(true);

      await updateProfile({
        travel_mode: draftMode ? [draftMode] : null,
        travel_style: draftStyle ? [draftStyle] : null,
        next_destination: draftNextDestination,
        languages: draftLanguages,
        lived_countries: draftLivedCountries,
      });

      router.back();
    } catch {
      Alert.alert('Save failed', 'Please try again.');
    } finally {
      setIsSavingProfile(false);
    }
  };

  const cancelAll = () => {
    setDraftMode(currentMode);
    setDraftStyle(currentStyle);
    setDraftNextDestination(profile?.next_destination ?? null);
    setDraftLanguages(profile?.languages ?? []);
    setDraftLivedCountries(profile?.lived_countries ?? []);
    router.back();
  };

  /* ---------------- Name / Username Edit ---------------- */

  const [editOpen, setEditOpen] = useState(false);
  const [editField, setEditField] = useState<EditField>('full_name');
  const [editValue, setEditValue] = useState('');

  const openEdit = (field: EditField) => {
    setEditField(field);
    setEditValue(
      field === 'full_name'
        ? profile?.full_name ?? ''
        : profile?.username ?? ''
    );
    setEditOpen(true);
  };

  const saveEdit = async () => {
    const trimmed = editValue.trim();
    if (!trimmed) {
      Alert.alert('Required', 'Field cannot be empty.');
      return;
    }

    try {
      if (editField === 'full_name') {
        await updateProfile({ full_name: trimmed });
      } else {
        await updateProfile({ username: trimmed.replace(/^@/, '') });
      }
      setEditOpen(false);
    } catch {
      Alert.alert('Update failed', 'Please try again.');
    }
  };

  /* ---------------- Labels ---------------- */

  const modeLabel =
    draftMode === 'solo'
      ? 'Solo'
      : draftMode === 'group'
      ? 'Group'
      : draftMode === 'both'
      ? 'Solo + Group'
      : '—';

  const styleLabel =
    draftStyle === 'budget'
      ? 'Budget'
      : draftStyle === 'comfortable'
      ? 'Comfortable'
      : draftStyle === 'luxury'
      ? 'Luxury'
      : '—';

  /* ---------------- UI ---------------- */

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.background }}>
      <ScrollView contentContainerStyle={{ paddingBottom: 60 }}>
        <View style={styles.navBar}>
          <Pressable onPress={cancelAll}>
            <Text style={[styles.navBtn, { color: colors.textPrimary }]}>
              Cancel
            </Text>
          </Pressable>

          <Pressable onPress={saveAll} disabled={isSavingProfile}>
            {isSavingProfile ? (
              <Text style={[styles.navBtn, { color: colors.textSecondary }]}>
                Saving…
              </Text>
            ) : (
              <Text
                style={[
                  styles.navBtn,
                  { color: colors.textPrimary },
                ]}
              >
                Save
              </Text>
            )}
          </Pressable>
        </View>

        <Text style={[styles.largeTitle, { color: colors.textPrimary }]}>
          Profile Settings
        </Text>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Pressable
            onPress={() => setAvatarMenuOpen(true)}
            style={{ alignItems: 'center', marginBottom: 20 }}
          >
            <View style={{ position: 'relative' }}>
              {profile?.avatar_url ? (
                <Image
                  source={{ uri: profile.avatar_url }}
                  style={{ width: 110, height: 110, borderRadius: 55 }}
                />
              ) : (
                <View
                  style={{
                    width: 110,
                    height: 110,
                    borderRadius: 55,
                    backgroundColor: colors.border,
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <Text style={{ fontSize: 32, color: colors.textSecondary }}>
                    👤
                  </Text>
                </View>
              )}

              {isUploadingAvatar && (
                <View
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    borderRadius: 55,
                    backgroundColor: 'rgba(0,0,0,0.4)',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <ActivityIndicator color="#fff" />
                </View>
              )}
            </View>

            <Text style={{ marginTop: 10, color: colors.primary, fontWeight: '600' }}>
              {profile?.avatar_url ? 'Edit Photo' : 'Add Photo'}
            </Text>
          </Pressable>
          <Divider color={borderColor} />
          <Row
            label="Name"
            value={profile?.full_name ?? '—'}
            onPress={() => openEdit('full_name')}
          />
          <Divider color={borderColor} />
          <Row
            label="Username"
            value={profile?.username ? `@${profile.username}` : '—'}
            onPress={() => openEdit('username')}
          />
        </View>

        <Modal visible={avatarMenuOpen} transparent animationType="fade">
          <Pressable
            style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)', justifyContent: 'flex-end' }}
            onPress={() => setAvatarMenuOpen(false)}
          >
            <View
              style={{
                backgroundColor: colors.card,
                padding: 24,
                borderTopLeftRadius: 24,
                borderTopRightRadius: 24,
              }}
            >
              <Pressable
                onPress={pickAvatar}
                style={{ paddingVertical: 16 }}
              >
                <Text style={{ fontSize: 16, fontWeight: '600', color: colors.textPrimary }}>
                  {profile?.avatar_url ? 'Change Photo' : 'Add Photo'}
                </Text>
              </Pressable>

              {profile?.avatar_url && (
                <Pressable
                  onPress={deleteAvatar}
                  style={{ paddingVertical: 16 }}
                >
                  <Text style={{ fontSize: 16, fontWeight: '600', color: colors.redText }}>
                    Remove Photo
                  </Text>
                </Pressable>
              )}

              <Pressable
                onPress={() => setAvatarMenuOpen(false)}
                style={{ paddingVertical: 16 }}
              >
                <Text style={{ fontSize: 16, fontWeight: '600', color: colors.textSecondary }}>
                  Cancel
                </Text>
              </Pressable>
            </View>
          </Pressable>
        </Modal>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Row label="Travel mode" value={modeLabel} />
          <Divider color={borderColor} />
          <Row label="Travel style" value={styleLabel} />
        </View>

        <View style={[styles.card, { backgroundColor: colors.card }]}> 
          <Pressable
            onPress={handleLogout}
            style={{
              borderWidth: 1,
              borderColor: borderColor,
              borderRadius: 16,
              paddingVertical: 16,
              alignItems: 'center',
            }}
          >
            <Text style={{ color: colors.textPrimary, fontWeight: '700', fontSize: 15 }}>
              Log out
            </Text>
          </Pressable>
        </View>

        <View style={[styles.card, { backgroundColor: colors.card }]}> 
          <Text style={{ fontSize: 16, fontWeight: '700', color: colors.redText, marginBottom: 12 }}>
            Danger Zone
          </Text>

          <Pressable
            onPress={() => setDeleteOpen(true)}
            style={{
              borderWidth: 1,
              borderColor: colors.redBorder,
              borderRadius: 16,
              paddingVertical: 16,
              alignItems: 'center',
            }}
          >
            <Text style={{ color: colors.redText, fontWeight: '700', fontSize: 15 }}>
              Delete account
            </Text>
          </Pressable>
        </View>
      </ScrollView>

      <Modal visible={editOpen} animationType="slide" transparent>
        <Pressable style={styles.modalBackdrop} onPress={() => setEditOpen(false)} />
        <View style={[styles.modalSheet, { backgroundColor: colors.card }]}>
          <Text style={[styles.modalTitle, { color: colors.textPrimary }]}>
            {editField === 'full_name' ? 'Edit Name' : 'Edit Username'}
          </Text>
          <TextInput
            value={editValue}
            onChangeText={setEditValue}
            style={[styles.input, { borderColor }]}
          />
          <Pressable onPress={saveEdit}>
            <Text style={{ color: colors.primary, fontWeight: '600' }}>
              Save
            </Text>
          </Pressable>
        </View>
      </Modal>

      <Modal visible={deleteOpen} animationType="fade" transparent>
        <Pressable
          style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', padding: 24 }}
          onPress={() => setDeleteOpen(false)}
        >
          <View
            style={{
              backgroundColor: colors.card,
              borderRadius: 20,
              padding: 20,
            }}
          >
            <Text style={{ fontSize: 18, fontWeight: '700', marginBottom: 8, color: colors.textPrimary }}>
              Delete account?
            </Text>

            <Text style={{ fontSize: 14, marginBottom: 20, color: colors.textSecondary }}>
              This action is permanent. Your account and all associated data will be deleted.
            </Text>

            <View style={{ flexDirection: 'row', gap: 12 }}>
              <Pressable
                onPress={() => setDeleteOpen(false)}
                style={{
                  flex: 1,
                  paddingVertical: 14,
                  borderRadius: 14,
                  alignItems: 'center',
                  borderWidth: 1,
                  borderColor: borderColor,
                }}
              >
                <Text style={{ fontWeight: '600', color: colors.textPrimary }}>
                  Cancel
                </Text>
              </Pressable>

              <Pressable
                onPress={handleDeleteAccount}
                disabled={deleting}
                style={{
                  flex: 1,
                  paddingVertical: 14,
                  borderRadius: 14,
                  alignItems: 'center',
                  borderWidth: 1,
                  borderColor: colors.redBorder,
                }}
              >
                <Text style={{ fontWeight: '700', color: colors.redText }}>
                  {deleting ? 'Deleting…' : 'Delete'}
                </Text>
              </Pressable>
            </View>
          </View>
        </Pressable>
      </Modal>
    </SafeAreaView>
  );
}

function Row({ label, value, onPress }: any) {
  const colors = useTheme();
  return (
    <Pressable style={styles.row} onPress={onPress}>
      <Text style={[styles.rowText, { color: colors.textPrimary }]}>
        {label}
      </Text>
      <Text style={[styles.rowValue, { color: colors.textSecondary }]}>
        {value}
      </Text>
    </Pressable>
  );
}

function Divider({ color }: { color: string }) {
  return <View style={[styles.divider, { backgroundColor: color }]} />;
}

const styles = StyleSheet.create({
  navBar: { flexDirection: 'row', justifyContent: 'space-between', padding: 20 },
  navBtn: { fontSize: 17, fontWeight: '600' },
  largeTitle: { fontSize: 34, fontWeight: '700', paddingHorizontal: 20 },
  card: {
    borderRadius: 20,
    padding: 20,
    marginHorizontal: 20,
    marginTop: 20,
    elevation: 2,
  },
  row: { paddingVertical: 18, flexDirection: 'row', justifyContent: 'space-between' },
  rowText: { fontSize: 16 },
  rowValue: { fontSize: 16 },
  divider: { height: StyleSheet.hairlineWidth },
  modalBackdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.3)' },
  modalSheet: { padding: 20 },
  modalTitle: { fontSize: 18, fontWeight: '700' },
  input: { borderWidth: 1, borderRadius: 12, padding: 12, marginVertical: 12 },
});