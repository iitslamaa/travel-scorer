import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Session } from '@supabase/supabase-js';

export type Profile = {
  id: string;
  username: string | null;
  display_name: string | null;
  onboarding_completed: boolean | null;
  avatar_url?: string | null;
  next_destination?: string | null;
};

type AuthContextType = {
  session: Session | null;
  loading: boolean;

  profile: Profile | null;
  profileLoading: boolean;

  isGuest: boolean;
  continueAsGuest: () => void;
  exitGuest: () => void;

  refreshProfile: () => Promise<void>;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  const [profile, setProfile] = useState<Profile | null>(null);
  const [profileLoading, setProfileLoading] = useState(false);

  const [isGuest, setIsGuest] = useState(false);

  const fetchProfile = async (userId: string) => {
    setProfileLoading(true);
    const { data, error } = await supabase
      .from('profiles')
      .select('id, username, display_name, onboarding_completed, avatar_url, next_destination')
      .eq('id', userId)
      .single();

    // If RLS blocks, you’ll see error here; for now we just null profile.
    setProfile(error ? null : (data as Profile));
    setProfileLoading(false);
  };

  const refreshProfile = async () => {
    const userId = session?.user?.id;
    if (!userId) return;
    await fetchProfile(userId);
  };

  useEffect(() => {
    const boot = async () => {
      const { data } = await supabase.auth.getSession();
      const s = data.session ?? null;
      setSession(s);
      setLoading(false);

      if (s?.user?.id) {
        await fetchProfile(s.user.id);
      }
    };

    boot();

    const { data: listener } = supabase.auth.onAuthStateChange((_event, newSession) => {
      const s = newSession ?? null;
      setSession(s);

      if (s?.user?.id) {
        setIsGuest(false);
        fetchProfile(s.user.id);
      } else {
        setProfile(null);
      }
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  const continueAsGuest = () => {
    setIsGuest(true);
    setSession(null);
    setProfile(null);
  };

  const exitGuest = () => {
    setIsGuest(false);
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setSession(null);
    setProfile(null);
    setIsGuest(false);
  };

  const value = useMemo<AuthContextType>(
    () => ({
      session,
      loading,
      profile,
      profileLoading,
      isGuest,
      continueAsGuest,
      exitGuest,
      refreshProfile,
      signOut,
    }),
    [session, loading, profile, profileLoading, isGuest]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}