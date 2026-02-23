import type { CountryFacts } from '@travel-af/shared';
import { AffordabilitySection as AffordabilityDisplay } from "@/lib/display/AffordabilitySection";

type Props = {
  facts?: CountryFacts;
  // later we can pass tripLengthDays here when you have date filters
};

export function AffordabilitySection({ facts }: Props) {
  if (!facts) return null;

  return <AffordabilityDisplay facts={facts} />;
}