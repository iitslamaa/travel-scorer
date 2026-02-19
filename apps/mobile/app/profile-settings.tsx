import { useEffect, useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  StyleSheet,
  Pressable,
  useColorScheme,
  ActionSheetIOS,
  Alert,
  Modal,
  TextInput,
  Platform,
  Image,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { lightColors, darkColors } from '../theme/colors';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { useCountries } from '../hooks/useCountries';

type EditField = 'full_name' | 'username';

export default function ProfileSettingsScreen() {
  const router = useRouter();
  const { profile, signOut, updateProfile } = useAuth();

  /* ---------------- Delete Account ---------------- */

  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const handleDeleteAccount = async () => {
    try {
      setDeleting(true);

      const { error } = await supabase.functions.invoke('delete-user', {
        body: {},
      });

      if (error) throw error;

      await signOut();
      await supabase.auth.signOut();

      router.replace('/(auth)/login');
    } catch (e: any) {
      Alert.alert('Delete failed', e?.message ?? 'Please try again.');
    } finally {
      setDeleting(false);
      setDeleteOpen(false);
    }
  };

  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? darkColors : lightColors;

  const borderColor =
    (colors as any).border ??
    (scheme === 'dark'
      ? 'rgba(255,255,255,0.12)'
      : 'rgba(0,0,0,0.08)');

  /* ---------------- Avatar ---------------- */

  const deleteAvatar = async () => {
    try {
      if (!profile?.avatar_url) return;
      const fileName = profile.avatar_url.split('/').pop();
      if (fileName) {
        await supabase.storage.from('avatars').remove([fileName]);
      }
      await updateProfile({ avatar_url: null });
    } catch {
      Alert.alert('Error', 'Failed to remove profile photo.');
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

          <Pressable onPress={saveAll} disabled={!hasChanges}>
            <Text style={[styles.navBtn, { color: hasChanges ? colors.textPrimary : colors.textSecondary }]}>
              Save
            </Text>
          </Pressable>
        </View>

        <Text style={[styles.largeTitle, { color: colors.textPrimary }]}>
          Profile Settings
        </Text>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
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

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Row label="Travel mode" value={modeLabel} />
          <Divider color={borderColor} />
          <Row label="Travel style" value={styleLabel} />
        </View>

        <View style={[styles.card, { backgroundColor: colors.card }]}> 
          <Text style={{ fontSize: 16, fontWeight: '700', color: '#EF4444', marginBottom: 12 }}>
            Danger Zone
          </Text>

          <Pressable
            onPress={() => setDeleteOpen(true)}
            style={{
              borderWidth: 1,
              borderColor: '#EF4444',
              borderRadius: 16,
              paddingVertical: 16,
              alignItems: 'center',
            }}
          >
            <Text style={{ color: '#EF4444', fontWeight: '700', fontSize: 15 }}>
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
            <Text>Save</Text>
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
                  borderColor: '#EF4444',
                }}
              >
                <Text style={{ fontWeight: '700', color: '#EF4444' }}>
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
  return (
    <Pressable style={styles.row} onPress={onPress}>
      <Text style={styles.rowText}>{label}</Text>
      <Text style={styles.rowValue}>{value}</Text>
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
  card: { borderRadius: 24, padding: 20, margin: 20 },
  row: { paddingVertical: 18, flexDirection: 'row', justifyContent: 'space-between' },
  rowText: { fontSize: 16 },
  rowValue: { fontSize: 16, opacity: 0.6 },
  divider: { height: StyleSheet.hairlineWidth },
  modalBackdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.3)' },
  modalSheet: { padding: 20 },
  modalTitle: { fontSize: 18, fontWeight: '700' },
  input: { borderWidth: 1, borderRadius: 12, padding: 12, marginVertical: 12 },
});