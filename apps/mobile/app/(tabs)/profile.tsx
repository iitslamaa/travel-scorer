import { View, Text } from 'react-native';
import AuthGate from '../../components/AuthGate';

export default function ProfileScreen() {
  return (
    <AuthGate>
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text>Profile Screen</Text>
      </View>
    </AuthGate>
  );
}