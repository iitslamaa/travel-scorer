import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export type PublicProfile = {
  id: string;
  username: string;
  full_name: string;
  avatar_url: string | null;

  // optional fields (only render if present)
  languages?: any; // could be json
  travel_mode?: string | null;
  travel_style?: string | null;
  next_destination?: string | null;
  lived_countries?: string[] | null;
};

export function useProfileById(userId?: string | string[]) {
  const id = Array.isArray(userId) ? userId[0] : userId;

  const [profile, setProfile] = useState<PublicProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;

    async function run() {
      setLoading(true);

      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', id)
        .single();

      if (error) {
        console.error(error);
        setProfile(null);
      } else {
        setProfile(data as PublicProfile);
      }

      setLoading(false);
    }

    run();
  }, [id]);

  return { profile, loading };
}