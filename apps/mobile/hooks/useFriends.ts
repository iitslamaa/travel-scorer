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

      // Get friend IDs
      const { data: friendRows, error: friendError } = await supabase
        .from('friends')
        .select('friend_id')
        .eq('user_id', userId);

      if (friendError) {
        console.error(friendError);
        setLoading(false);
        return;
      }

      const friendIds = friendRows.map(f => f.friend_id);

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
        setFriends((profiles as FriendProfile[]) ?? []);
      }

      setLoading(false);
    }

    fetchFriends();
  }, [user]);

  return { friends, loading };
}