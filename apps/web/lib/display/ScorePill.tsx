'use client';
import React from 'react';

export function toneClass(n?: number) {
  if (typeof n !== 'number') return 'bg-zinc-100 text-zinc-700 border-zinc-200';
  if (n >= 80) return 'bg-green-100 text-green-800 border-green-300';
  if (n >= 60) return 'bg-yellow-100 text-yellow-800 border-yellow-300';
  if (n > 0)   return 'bg-red-100 text-red-800 border-red-300';
  return 'bg-black text-white border-black';
}

export function ScorePill({ value, title }: { value?: number; title?: string }) {
  return (
    <span
      title={title}
      className={`inline-flex h-7 min-w-[2.25rem] items-center justify-center rounded-full border px-2 text-sm font-semibold ${toneClass(value)}`}
    >
      {typeof value === 'number' ? Math.round(value) : '—'}
    </span>
  );
}