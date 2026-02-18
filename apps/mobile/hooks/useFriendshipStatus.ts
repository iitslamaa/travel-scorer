import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';

export function useFriendshipStatus(viewedUserId?: string | string[]) {
  const { session } = useAuth();
  const viewerId = session?.user?.id;
  const targetId = Array.isArray(viewedUserId) ? viewedUserId[0] : viewedUserId;

  const [isFriend, setIsFriend] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!viewerId || !targetId) return;

    async function run() {
      setLoading(true);

      const { data, error } = await supabase
        .from('friends')
        .select('id')
        .or(
          `and(user_id.eq.${viewerId},friend_id.eq.${targetId}),and(user_id.eq.${targetId},friend_id.eq.${viewerId})`
        )
        .limit(1);

      if (error) {
        console.error(error);
        setIsFriend(false);
      } else {
        setIsFriend((data?.length ?? 0) > 0);
      }

      setLoading(false);
    }

    run();
  }, [viewerId, targetId]);

  return { isFriend, loading };
}