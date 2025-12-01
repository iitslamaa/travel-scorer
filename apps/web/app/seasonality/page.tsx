import type { Metadata } from 'next';
import { SeasonalityExplorer } from '@/components/seasonality/SeasonalityExplorer';

export const metadata: Metadata = {
  title: 'When to Go | TravelScorer',
  description:
    'Pick a month and instantly see which destinations are in peak or shoulder season.',
};

export default function SeasonalityPage() {
  return (
    <main className="min-h-screen bg-stone-50">
      <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:px-8">
        <header className="mb-8">
          <h1 className="text-3xl font-semibold tracking-tight text-stone-900 sm:text-4xl">
            When to Go
          </h1>
          <p className="mt-2 max-w-2xl text-sm text-stone-600 sm:text-base">
            Select a month to explore where it&apos;s peak or shoulder season
            around the world.
          </p>
        </header>

        <SeasonalityExplorer />
      </div>
    </main>
  );
}