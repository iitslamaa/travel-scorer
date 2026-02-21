import { useMemo } from 'react';
import worldGeo from '../../../assets/geo/world.geo.json';

export function useGeoJson() {
  const features = useMemo(() => {
    return (worldGeo as any)?.features ?? [];
  }, []);

  return { features };
}