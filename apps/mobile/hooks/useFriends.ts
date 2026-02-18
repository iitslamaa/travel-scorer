import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';

export type FriendProfile = {
  id: string;
  username: string;
  full_name: string;
  avatar_url: string | null;
};

export function useFriends() {
  const { session } = useAuth();
  const user = session?.user;
  const [friends, setFriends] = useState<FriendProfile[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    const userId = user.id;

    async function fetchFriends() {
      setLoading(true);

      // Get friend rows where I am either user_id OR friend_id
      const { data: friendRows, error: friendError } = await supabase
        .from('friends')
        .select('user_id, friend_id')
        .or(`user_id.eq.${userId},friend_id.eq.${userId}`);

      if (friendError) {
        console.error(friendError);
        setLoading(false);
        return;
      }

      // Compute the "other" user id for each row
      const ids = (friendRows ?? []).flatMap((row: any) => {
        if (row.user_id === userId) return [row.friend_id];
        if (row.friend_id === userId) return [row.user_id];
        return [];
      });

      // Deduplicate
      const friendIds = Array.from(new Set(ids)).filter(Boolean);

      if (friendIds.length === 0) {
        setFriends([]);
        setLoading(false);
        return;
      }

      // Fetch profiles
      const { data: profiles, error: profileError } = await supabase
        .from('profiles')
        .select('id, username, full_name, avatar_url')
        .in('id', friendIds);

      if (profileError) {
        console.error(profileError);
      } else {
        const typedProfiles = (profiles as FriendProfile[]) ?? [];
        const sorted = typedProfiles.sort((a, b) =>
          (a.full_name ?? '').localeCompare(b.full_name ?? '')
        );
        setFriends(sorted);
      }

      setLoading(false);
    }

    fetchFriends();
  }, [user]);

  return { friends, loading };
}