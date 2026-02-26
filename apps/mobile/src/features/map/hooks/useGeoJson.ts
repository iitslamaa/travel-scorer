import { useMemo } from 'react';
import worldFull from '../../../../assets/geo/countries.geo.json';
import worldSimplified from '../../../../assets/geo/countries.simplified.geo.json';

export function useGeoJson() {
  const fullFeatures = useMemo(() => {
    return (worldFull as any)?.features ?? [];
  }, []);

  const simplifiedFeatures = useMemo(() => {
    return (worldSimplified as any)?.features ?? [];
  }, []);

  return {
    fullFeatures,
    simplifiedFeatures,
  };
}