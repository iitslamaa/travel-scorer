import { View, Text } from 'react-native';
import AuthGate from '../../components/AuthGate';

export default function WhenToGoScreen() {
  return (
    <AuthGate>
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text>When to Go Screen</Text>
      </View>
    </AuthGate>
  );
}