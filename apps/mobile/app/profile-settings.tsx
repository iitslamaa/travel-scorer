import { useEffect, useMemo, useState } from 'react';
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
import { useRouter } from 'expo-router';
import { lightColors, darkColors } from '../theme/colors';
import { useAuth } from '../context/AuthContext';

type EditField = 'display_name' | 'username';

export default function ProfileSettingsScreen() {
  const router = useRouter();
  const { profile, signOut, updateProfile } = useAuth();

  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? darkColors : lightColors;

  const borderColor =
    (colors as any).border ??
    (scheme === 'dark'
      ? 'rgba(255,255,255,0.12)'
      : 'rgba(0,0,0,0.08)');

  // -----------------------------
  // Draft State (Save / Cancel)
  // -----------------------------

  const [draftMode, setDraftMode] = useState<string | null>(null);
  const [draftStyle, setDraftStyle] = useState<string | null>(null);

  useEffect(() => {
    setDraftMode(profile?.travel_mode ?? null);
    setDraftStyle(profile?.travel_style ?? null);
  }, [profile]);

  const hasChanges =
    draftMode !== profile?.travel_mode ||
    draftStyle !== profile?.travel_style;

  const saveAll = async () => {
    try {
      await updateProfile({
        travel_mode: draftMode,
        travel_style: draftStyle,
      });
      router.back();
    } catch (e: any) {
      Alert.alert('Save failed', e?.message ?? 'Please try again.');
    }
  };

  const cancelAll = () => {
    setDraftMode(profile?.travel_mode ?? null);
    setDraftStyle(profile?.travel_style ?? null);
    router.back();
  };

  // -----------------------------
  // Labels
  // -----------------------------

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

  // -----------------------------
  // Pickers (no auto-save)
  // -----------------------------

  const pickMode = () => {
    const options = ['Solo', 'Group', 'Solo + Group', 'Cancel'];
    const cancelButtonIndex = 3;

    const apply = (index: number) => {
      if (index === cancelButtonIndex) return;
      const value =
        index === 0 ? 'solo' : index === 1 ? 'group' : 'both';
      setDraftMode(value);
    };

    if (Platform.OS === 'ios') {
      ActionSheetIOS.showActionSheetWithOptions(
        { options, cancelButtonIndex },
        apply
      );
    } else {
      Alert.alert('Travel mode', '', [
        { text: 'Solo', onPress: () => apply(0) },
        { text: 'Group', onPress: () => apply(1) },
        { text: 'Solo + Group', onPress: () => apply(2) },
        { text: 'Cancel', style: 'cancel' },
      ]);
    }
  };

  const pickStyle = () => {
    const options = ['Budget', 'Comfortable', 'Luxury', 'Cancel'];
    const cancelButtonIndex = 3;

    const apply = (index: number) => {
      if (index === cancelButtonIndex) return;
      const value =
        index === 0 ? 'budget' : index === 1 ? 'comfortable' : 'luxury';
      setDraftStyle(value);
    };

    if (Platform.OS === 'ios') {
      ActionSheetIOS.showActionSheetWithOptions(
        { options, cancelButtonIndex },
        apply
      );
    } else {
      Alert.alert('Travel style', '', [
        { text: 'Budget', onPress: () => apply(0) },
        { text: 'Comfortable', onPress: () => apply(1) },
        { text: 'Luxury', onPress: () => apply(2) },
        { text: 'Cancel', style: 'cancel' },
      ]);
    }
  };

  // -----------------------------
  // Edit Name / Username
  // -----------------------------

  const [editOpen, setEditOpen] = useState(false);
  const [editField, setEditField] = useState<EditField>('display_name');
  const [editValue, setEditValue] = useState('');
  const [saving, setSaving] = useState(false);

  const openEdit = (field: EditField) => {
    setEditField(field);
    const current =
      field === 'display_name'
        ? profile?.display_name ?? ''
        : profile?.username ?? '';
    setEditValue(current);
    setEditOpen(true);
  };

  const saveEdit = async () => {
    const trimmed = editValue.trim();
    if (!trimmed) {
      Alert.alert('Required', 'Field cannot be empty.');
      return;
    }

    setSaving(true);
    try {
      if (editField === 'display_name') {
        await updateProfile({ display_name: trimmed });
      } else {
        await updateProfile({ username: trimmed.replace(/^@/, '') });
      }
      setEditOpen(false);
    } catch (e: any) {
      Alert.alert('Update failed', e?.message ?? 'Please try again.');
    } finally {
      setSaving(false);
    }
  };

  // -----------------------------
  // UI
  // -----------------------------

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: colors.background }}
      showsVerticalScrollIndicator={false}
    >
      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={cancelAll}>
          <Text style={[styles.headerBtn, { color: colors.textPrimary }]}>
            Cancel
          </Text>
        </Pressable>

        <Text style={[styles.headerTitle, { color: colors.textPrimary }]}>
          Profile Settings
        </Text>

        <Pressable onPress={saveAll} disabled={!hasChanges}>
          <Text
            style={[
              styles.headerBtn,
              {
                color: hasChanges
                  ? colors.textPrimary
                  : colors.textSecondary,
              },
            ]}
          >
            Save
          </Text>
        </Pressable>
      </View>

      {/* Profile Photo */}
      <View style={styles.photoSection}>
        {profile?.avatar_url ? (
          <Image
            source={{ uri: profile.avatar_url }}
            style={styles.avatar}
          />
        ) : (
          <View
            style={[styles.avatar, { backgroundColor: borderColor }]}
          />
        )}

        <Pressable>
          <Text
            style={[
              styles.editPhoto,
              { color: colors.textPrimary },
            ]}
          >
            Edit
          </Text>
        </Pressable>
      </View>

      {/* Info Group */}
      <View
        style={[
          styles.group,
          { borderColor, backgroundColor: colors.card },
        ]}
      >
        <Row
          label="Edit name"
          value={profile?.display_name ?? '—'}
          onPress={() => openEdit('display_name')}
        />
        <Divider color={borderColor} />
        <Row
          label="Edit username"
          value={
            profile?.username ? `@${profile.username}` : '—'
          }
          onPress={() => openEdit('username')}
        />
      </View>

      <Text
        style={[
          styles.sectionLabel,
          { color: colors.textSecondary },
        ]}
      >
        Travel Preferences
      </Text>

      <View
        style={[
          styles.group,
          { borderColor, backgroundColor: colors.card },
        ]}
      >
        <Row label="Travel mode" value={modeLabel} onPress={pickMode} />
        <Divider color={borderColor} />
        <Row label="Travel style" value={styleLabel} onPress={pickStyle} />
      </View>

      <View
        style={[
          styles.group,
          { borderColor, backgroundColor: colors.card },
        ]}
      >
        <Row label="Sign Out" danger onPress={signOut} />
      </View>

      {/* Modal */}
      <Modal visible={editOpen} animationType="slide" transparent>
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setEditOpen(false)}
        />

        <View
          style={[
            styles.modalSheet,
            { backgroundColor: colors.card },
          ]}
        >
          <Text
            style={[
              styles.modalTitle,
              { color: colors.textPrimary },
            ]}
          >
            {editField === 'display_name'
              ? 'Edit Name'
              : 'Edit Username'}
          </Text>

          <TextInput
            value={editValue}
            onChangeText={setEditValue}
            style={[
              styles.input,
              {
                color: colors.textPrimary,
                borderColor,
              },
            ]}
          />

          <View style={styles.modalBtns}>
            <Pressable
              style={[styles.btn, { borderColor }]}
              onPress={() => setEditOpen(false)}
            >
              <Text style={{ color: colors.textPrimary }}>
                Cancel
              </Text>
            </Pressable>

            <Pressable
              style={[
                styles.btnPrimary,
                { backgroundColor: colors.textPrimary },
              ]}
              onPress={saveEdit}
            >
              <Text style={{ color: colors.background }}>
                {saving ? 'Saving…' : 'Save'}
              </Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
}

function Row({ label, value, onPress, danger }: any) {
  return (
    <Pressable style={styles.row} onPress={onPress}>
      <Text
        style={[
          styles.rowText,
          danger && { color: '#E5484D' },
        ]}
      >
        {label}
      </Text>
      {value && <Text style={styles.rowValue}>{value}</Text>}
    </Pressable>
  );
}

function Divider({ color }: { color: string }) {
  return <View style={[styles.divider, { backgroundColor: color }]} />;
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 20,
    marginBottom: 20,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
  },
  headerBtn: {
    fontSize: 16,
    fontWeight: '600',
  },
  photoSection: {
    alignItems: 'center',
    marginBottom: 30,
  },
  avatar: {
    width: 110,
    height: 110,
    borderRadius: 55,
    marginBottom: 8,
  },
  editPhoto: {
    fontSize: 15,
    fontWeight: '600',
  },
  sectionLabel: {
    fontSize: 13,
    fontWeight: '600',
    paddingHorizontal: 20,
    marginBottom: 8,
  },
  group: {
    borderRadius: 18,
    borderWidth: 1,
    marginHorizontal: 20,
    marginBottom: 20,
    overflow: 'hidden',
  },
  row: {
    paddingVertical: 18,
    paddingHorizontal: 18,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  rowText: {
    fontSize: 16,
    fontWeight: '500',
  },
  rowValue: {
    fontSize: 16,
    opacity: 0.6,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    marginLeft: 18,
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  modalSheet: {
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    padding: 20,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 12,
  },
  input: {
    borderWidth: 1,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 16,
    marginBottom: 16,
  },
  modalBtns: {
    flexDirection: 'row',
    gap: 12,
  },
  btn: {
    flex: 1,
    borderWidth: 1,
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: 'center',
  },
  btnPrimary: {
    flex: 1,
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: 'center',
  },
});