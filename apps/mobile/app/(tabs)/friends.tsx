import { View, Text } from 'react-native';
import AuthGate from '../../components/AuthGate';

export default function FriendsScreen() {
  return (
    <AuthGate>
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text>Friends Screen</Text>
      </View>
    </AuthGate>
  );
}