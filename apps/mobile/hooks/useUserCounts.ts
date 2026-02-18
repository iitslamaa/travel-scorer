import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export function useUserCounts(userId?: string | string[]) {
  const id = Array.isArray(userId) ? userId[0] : userId;

  const [traveledCount, setTraveledCount] = useState(0);
  const [bucketCount, setBucketCount] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;

    async function run() {
      setLoading(true);

      const [
        { count: traveledCountRes, error: traveledErr },
        { count: bucketCountRes, error: bucketErr },
      ] = await Promise.all([
        supabase
          .from('user_traveled')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', id),

        supabase
          .from('user_bucket_list')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', id),
      ]);

      if (traveledErr) console.error(traveledErr);
      if (bucketErr) console.error(bucketErr);

      setTraveledCount(traveledCountRes ?? 0);
      setBucketCount(bucketCountRes ?? 0);

      setLoading(false);
    }

    run();
  }, [id]);

  return { traveledCount, bucketCount, loading };
}