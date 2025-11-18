"use client";

// apps/web/app/map/page.tsx

import dynamic from "next/dynamic";
import { AIRPORTS } from "../../../../packages/data/src";

const WorldMap = dynamic(() => import("../../components/map/WorldMap"), {
  ssr: false,
});

export default function MapPage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col gap-6 px-4 py-8">
      <header className="max-w-xl">
        <h1 className="text-2xl font-semibold text-neutral-900">
          Explore airports on the map
        </h1>
        <p className="mt-1 text-sm text-neutral-600">
          This is a simple starter map using your seed airport data. We&apos;ll
          later connect this to score pills and city pages.
        </p>
      </header>

      <WorldMap airports={AIRPORTS} />
    </main>
  );
}