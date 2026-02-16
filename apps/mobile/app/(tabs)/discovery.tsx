import { View, Text } from 'react-native';
import AuthGate from '../../components/AuthGate';

export default function DiscoveryScreen() {
  return (
    <AuthGate>
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text>Discovery Screen</Text>
      </View>
    </AuthGate>
  );
}