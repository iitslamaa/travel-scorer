import { View, Text } from 'react-native';
import AuthGate from '../../components/AuthGate';

export default function MoreScreen() {
  return (
    <AuthGate>
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <Text>More Screen</Text>
      </View>
    </AuthGate>
  );
}