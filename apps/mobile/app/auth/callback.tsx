import { View, ActivityIndicator } from 'react-native';
import { useEffect } from 'react';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { supabase } from '../../lib/supabase';

export default function AuthCallback() {
  const router = useRouter();
  const params = useLocalSearchParams();

  useEffect(() => {
    const handleAuth = async () => {
      try {
        // Supabase sends `code` back in the redirect URL
        const code = params.code as string | undefined;

        if (code) {
          const { error } = await supabase.auth.exchangeCodeForSession(code);

          if (error) {
            console.error('OAuth exchange error:', error);
            return;
          }
        }

        router.replace('/home');
      } catch (err) {
        console.error('Auth callback error:', err);
      }
    };

    handleAuth();
  }, [params]);

  return (
    <View
      style={{
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <ActivityIndicator size="large" />
    </View>
  );
}