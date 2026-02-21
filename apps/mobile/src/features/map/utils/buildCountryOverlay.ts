import { CountryFeatureOverlay } from '../types/map.types';

type OverlayParams = {
  iso: string;
  selectedIso?: string;
  score?: number;
};

export function buildCountryOverlay({
  iso,
  selectedIso,
  score,
}: OverlayParams): CountryFeatureOverlay {
  const isSelected = selectedIso === iso;

  // Selected overrides everything
  if (isSelected) {
    return {
      iso,
      strokeColor: '#000000',
      fillColor: 'rgba(255, 215, 0, 0.6)',
    };
  }

  // Score-based coloring
  if (typeof score === 'number') {
    if (score >= 80) {
      return {
        iso,
        strokeColor: '#14532d',
        fillColor: 'rgba(34, 197, 94, 0.45)',
      };
    }

    if (score >= 60) {
      return {
        iso,
        strokeColor: '#92400e',
        fillColor: 'rgba(234, 179, 8, 0.45)',
      };
    }

    if (score >= 40) {
      return {
        iso,
        strokeColor: '#9a3412',
        fillColor: 'rgba(249, 115, 22, 0.45)',
      };
    }

    return {
      iso,
      strokeColor: '#7f1d1d',
      fillColor: 'rgba(239, 68, 68, 0.45)',
    };
  }

  // Neutral default state
  return {
    iso,
    strokeColor: '#1f2937',
    fillColor: 'rgba(148, 163, 184, 0.15)',
  };
}