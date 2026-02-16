import { View, Text, Pressable } from 'react-native';
import AuthGate from '../components/AuthGate';
import { useAuth } from '../context/AuthContext';

export default function HomeScreen() {
  const { signOut, isGuest, profile } = useAuth();

  const name =
    profile?.display_name ??
    profile?.username ??
    (isGuest ? 'Guest' : 'Traveler');

  return (
    <AuthGate>
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text>Welcome to TravelScorer</Text>
        <Text style={{ marginTop: 8 }}>
          {name} {isGuest ? '(Guest Mode)' : ''}
        </Text>

        <Pressable onPress={signOut} style={{ marginTop: 20 }}>
          <Text>Sign Out</Text>
        </Pressable>
      </View>
    </AuthGate>
  );
}