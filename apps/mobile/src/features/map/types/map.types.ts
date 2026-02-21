export type CountryISO = string;

export type CountryFeatureOverlay = {
  iso: CountryISO;
  fillColor: string;
  strokeColor?: string;
  opacity?: number;
};

export type WorldMapProps = {
  overlays?: CountryFeatureOverlay[];
  selectedISO?: CountryISO | null;
  onCountryPress?: (iso: CountryISO) => void;
};