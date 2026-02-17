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

import { useCountries } from '../hooks/useCountries';

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

  const [draftMode, setDraftMode] = useState<string | null>(null);
  const [draftStyle, setDraftStyle] = useState<string | null>(null);

  const { countries } = useCountries();
  const [draftNextDestination, setDraftNextDestination] = useState<string | null>(null);
  const [draftLivedCountries, setDraftLivedCountries] = useState<string[]>([]);

  type LanguageEntry = {
    name: string;
    proficiency: 'Native' | 'Fluent' | 'Learning';
  };

  const [draftLanguages, setDraftLanguages] = useState<LanguageEntry[]>([]);
  const [languageModalOpen, setLanguageModalOpen] = useState(false);
  const [newLanguage, setNewLanguage] = useState('');
  const [newProficiency, setNewProficiency] = useState<'Native' | 'Fluent' | 'Learning'>('Fluent');

  useEffect(() => {
    console.log('PROFILE LANGUAGES:', profile?.languages);
    setDraftMode(profile?.travel_mode ?? null);
    setDraftStyle(profile?.travel_style ?? null);
    setDraftNextDestination(profile?.next_destination ?? null);
    if (profile?.languages && Array.isArray(profile.languages)) {
      setDraftLanguages(profile.languages);
    } else {
      setDraftLanguages([]);
    }
    if (profile?.lived_countries && Array.isArray(profile.lived_countries)) {
      setDraftLivedCountries(profile.lived_countries);
    } else {
      setDraftLivedCountries([]);
    }
  }, [profile]);

  const hasChanges =
    draftMode !== profile?.travel_mode ||
    draftStyle !== profile?.travel_style ||
    draftNextDestination !== profile?.next_destination ||
    JSON.stringify(draftLanguages) !== JSON.stringify(profile?.languages ?? []) ||
    JSON.stringify(draftLivedCountries) !== JSON.stringify(profile?.lived_countries ?? []);

  const saveAll = async () => {
    try {
      await updateProfile({
        travel_mode: draftMode,
        travel_style: draftStyle,
        next_destination: draftNextDestination,
        languages: draftLanguages,
        lived_countries: draftLivedCountries,
      });
      router.back();
    } catch (e: any) {
      Alert.alert('Save failed', e?.message ?? 'Please try again.');
    }
  };

  const cancelAll = () => {
    setDraftMode(profile?.travel_mode ?? null);
    setDraftStyle(profile?.travel_style ?? null);
    setDraftNextDestination(profile?.next_destination ?? null);
    setDraftLanguages(profile?.languages ?? []);
    setDraftLivedCountries(profile?.lived_countries ?? []);
    router.back();
  };
  const pickNextDestination = () => {
    if (!countries || countries.length === 0) return;

    const sorted = [...countries].sort((a, b) =>
      a.name.localeCompare(b.name)
    );

    const options = sorted.map(c => `${c.flagEmoji ?? ''} ${c.name}`);
    options.push('Cancel');

    const cancelButtonIndex = options.length - 1;

    const apply = (index: number) => {
      if (index === cancelButtonIndex) return;
      const selected = sorted[index];
      setDraftNextDestination(selected.name);
    };

    if (Platform.OS === 'ios') {
      ActionSheetIOS.showActionSheetWithOptions(
        { options, cancelButtonIndex },
        apply
      );
    } else {
      Alert.alert(
        'Select Destination',
        '',
        sorted.map((c, i) => ({
          text: `${c.flagEmoji ?? ''} ${c.name}`,
          onPress: () => apply(i),
        })).concat([{ text: 'Cancel', style: 'cancel' }])
      );
    }
  };

  const addLanguage = () => {
    const trimmed = newLanguage.trim();
    if (!trimmed) return;

    setDraftLanguages(prev => [
      ...prev,
      { name: trimmed, proficiency: newProficiency },
    ]);

    setNewLanguage('');
    setNewProficiency('Fluent');
  };

  const removeLanguage = (index: number) => {
    setDraftLanguages(prev => prev.filter((_, i) => i !== index));
  };

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

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.background }}>
      <ScrollView
        contentContainerStyle={{ paddingBottom: 60 }}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.navBar}>
          <Pressable onPress={cancelAll}>
            <Text style={[styles.navBtn, { color: colors.textPrimary }]}>
              Cancel
            </Text>
          </Pressable>

          <Pressable onPress={saveAll} disabled={!hasChanges}>
            <Text
              style={[
                styles.navBtn,
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

        <Text style={[styles.largeTitle, { color: colors.textPrimary }]}>
          Profile Settings
        </Text>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
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
              style={[styles.changePhoto, { color: colors.textSecondary }]}
            >
              Change profile photo
            </Text>
          </Pressable>
        </View>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Row
            label="Name"
            value={profile?.display_name ?? '—'}
            onPress={() => openEdit('display_name')}
          />
          <Divider color={borderColor} />
          <Row
            label="Username"
            value={profile?.username ? `@${profile.username}` : '—'}
            onPress={() => openEdit('username')}
          />
        </View>

        <Text
          style={[styles.sectionTitle, { color: colors.textSecondary }]}
        >
          Travel Preferences
        </Text>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Row label="Travel mode" value={modeLabel} onPress={pickMode} />
          <Divider color={borderColor} />
          <Row label="Travel style" value={styleLabel} onPress={pickStyle} />
        </View>

        {/* Languages */}
        <Text
          style={[styles.sectionTitle, { color: colors.textSecondary }]}
        >
          Languages
        </Text>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Row
            label="Languages spoken"
            value={
              draftLanguages.length > 0
                ? draftLanguages
                    .map(l => `${l.name} (${l.proficiency})`)
                    .join(', ')
                : '—'
            }
            onPress={() => setLanguageModalOpen(true)}
          />
        </View>

        {/* Next Destination */}
        <Text
          style={[styles.sectionTitle, { color: colors.textSecondary }]}
        >
          Next Destination
        </Text>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Row
            label="Next destination"
            value={
              draftNextDestination
                ? (() => {
                    const match = countries?.find(
                      c =>
                        c.name === draftNextDestination ||
                        c.iso2 === draftNextDestination
                    );
                    return match
                      ? `${match.flagEmoji ?? ''} ${match.name}`
                      : draftNextDestination;
                  })()
                : '—'
            }
            onPress={pickNextDestination}
          />
        </View>

        {/* Home Countries */}
        <Text
          style={[styles.sectionTitle, { color: colors.textSecondary }]}
        >
          Home Countries
        </Text>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Row
            label="Which countries do you consider home?"
            value={
              draftLivedCountries.length > 0
                ? draftLivedCountries
                    .map(code => {
                      const match = countries?.find(c => c.iso2 === code);
                      return match ? `${match.flagEmoji ?? ''} ${match.name}` : code;
                    })
                    .join(', ')
                : '—'
            }
            onPress={() => {
              if (!countries || countries.length === 0) return;

              const sorted = [...countries].sort((a, b) =>
                a.name.localeCompare(b.name)
              );

              const options = sorted.map(c => {
                const selected = draftLivedCountries.includes(c.iso2);
                return `${selected ? '✓ ' : ''}${c.flagEmoji ?? ''} ${c.name}`;
              });

              options.push('Done');
              const doneIndex = options.length - 1;

              const apply = (index: number) => {
                if (index === doneIndex) return;

                const selectedCountry = sorted[index];
                setDraftLivedCountries(prev => {
                  if (prev.includes(selectedCountry.iso2)) {
                    return prev.filter(c => c !== selectedCountry.iso2);
                  }
                  return [...prev, selectedCountry.iso2];
                });
              };

              if (Platform.OS === 'ios') {
                ActionSheetIOS.showActionSheetWithOptions(
                  { options, cancelButtonIndex: doneIndex },
                  apply
                );
              } else {
                Alert.alert(
                  'Select Home Countries',
                  '',
                  sorted
                    .map((c, i) => ({
                      text: `${draftLivedCountries.includes(c.iso2) ? '✓ ' : ''}${c.flagEmoji ?? ''} ${c.name}`,
                      onPress: () => apply(i),
                    }))
                    .concat([{ text: 'Done', style: 'cancel' }])
                );
              }
            }}
          />
        </View>

        {/* Sign Out */}
        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Row label="Sign Out" danger onPress={signOut} />
        </View>
      </ScrollView>

      <Modal visible={editOpen} animationType="slide" transparent>
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setEditOpen(false)}
        />

        <View style={[styles.modalSheet, { backgroundColor: colors.card }]}>
          <Text
            style={[styles.modalTitle, { color: colors.textPrimary }]}
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
              <Text style={{ color: colors.textPrimary }}>Cancel</Text>
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

      <Modal visible={languageModalOpen} animationType="slide" transparent>
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setLanguageModalOpen(false)}
        />

        <View style={[styles.modalSheet, { backgroundColor: colors.card }]}> 
          <Text style={[styles.modalTitle, { color: colors.textPrimary }]}> 
            Edit Languages
          </Text>

          {draftLanguages.map((lang, index) => (
            <View key={index} style={{ marginBottom: 8, flexDirection: 'row', justifyContent: 'space-between' }}>
              <Text style={{ color: colors.textPrimary }}>
                {lang.name} ({lang.proficiency})
              </Text>
              <Pressable onPress={() => removeLanguage(index)}>
                <Text style={{ color: '#E5484D' }}>Remove</Text>
              </Pressable>
            </View>
          ))}

          <TextInput
            placeholder="Add language"
            placeholderTextColor={colors.textSecondary}
            value={newLanguage}
            onChangeText={setNewLanguage}
            style={[
              styles.input,
              { color: colors.textPrimary, borderColor },
            ]}
          />

          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 12 }}>
            {['Native', 'Fluent', 'Learning'].map(level => (
              <Pressable
                key={level}
                onPress={() => setNewProficiency(level as any)}
                style={{
                  paddingVertical: 8,
                  paddingHorizontal: 12,
                  borderRadius: 12,
                  backgroundColor:
                    newProficiency === level
                      ? colors.textPrimary
                      : borderColor,
                }}
              >
                <Text
                  style={{
                    color:
                      newProficiency === level
                        ? colors.background
                        : colors.textPrimary,
                  }}
                >
                  {level}
                </Text>
              </Pressable>
            ))}
          </View>

          <View style={styles.modalBtns}>
            <Pressable
              style={[styles.btn, { borderColor }]}
              onPress={() => setLanguageModalOpen(false)}
            >
              <Text style={{ color: colors.textPrimary }}>Done</Text>
            </Pressable>

            <Pressable
              style={[styles.btnPrimary, { backgroundColor: colors.textPrimary }]}
              onPress={addLanguage}
            >
              <Text style={{ color: colors.background }}>Add</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
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

      {value ? (
        <Text
          style={styles.rowValue}
          numberOfLines={1}
          ellipsizeMode="tail"
        >
          {value}
        </Text>
      ) : null}
    </Pressable>
  );
}

function Divider({ color }: { color: string }) {
  return <View style={[styles.divider, { backgroundColor: color }]} />;
}

const styles = StyleSheet.create({
  navBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 24,
    paddingTop: 10,
  },

  navBtn: {
    fontSize: 17,
    fontWeight: '600',
  },

  largeTitle: {
    fontSize: 34,
    fontWeight: '700',
    paddingHorizontal: 24,
    marginTop: 12,
    marginBottom: 20,
  },

  card: {
    borderRadius: 24,
    padding: 22,
    marginHorizontal: 20,
    marginBottom: 22,
  },

  avatar: {
    width: 110,
    height: 110,
    borderRadius: 55,
    alignSelf: 'center',
    marginBottom: 12,
  },

  changePhoto: {
    fontSize: 15,
    textAlign: 'center',
  },

  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    paddingHorizontal: 24,
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },

  row: {
    paddingVertical: 18,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },

  rowText: {
    fontSize: 16,
    fontWeight: '500',
  },

  rowValue: {
    fontSize: 16,
    opacity: 0.6,
    marginLeft: 12,
    flexShrink: 1,
    textAlign: 'right',
  },

  divider: {
    height: StyleSheet.hairlineWidth,
    marginVertical: 2,
  },

  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.3)',
  },

  modalSheet: {
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
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