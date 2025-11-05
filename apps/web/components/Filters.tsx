'use client';
import { useState, useEffect } from 'react';
import { DEFAULT_WEIGHTS, type Weights } from '@/lib/score';

type Props = { onChange: (w: Weights, month: number, tags: string[]) => void };

export default function Filters({ onChange }: Props) {
  const [w, setW] = useState<Weights>({ ...DEFAULT_WEIGHTS });
  const [month, setMonth] = useState<number>(new Date().getMonth() + 1);
  const [tags, setTags] = useState<string[]>([]);

  useEffect(() => { onChange(w, month, tags); }, []); // kick initial compute

  const updateWeight = (k: keyof Weights, v: number) => {
    const next = { ...w, [k]: v };
    setW(next);
    onChange(next, month, tags);
  };
  const updateMonth = (v: number) => { setMonth(v); onChange(w, v, tags); };
  const toggleTag = (t: string) => {
    const next = tags.includes(t) ? tags.filter(x => x !== t) : [...tags, t];
    setTags(next);
    onChange(w, month, next);
  };

  const slider = (label: string, key: keyof Weights) => (
    <div className="mb-3">
      <label className="block text-sm font-medium mb-1">{label}: {(w[key] * 100).toFixed(0)}%</label>
      <input type="range" min={0} max={0.4} step={0.01}
        value={w[key]} onChange={(e)=>updateWeight(key, Number(e.target.value))}
        className="w-full"/>
    </div>
  );

  const TAGS = ['food','nature','activities','architecture','history'];

  return (
    <div className="p-4 bg-white/60 dark:bg-zinc-900/60 rounded-lg border border-zinc-200 dark:border-zinc-800">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          {slider('Safety','safety')}
          {slider('Affordability','affordability')}
          {slider('English','english')}
          {slider('Seasonality','seasonality')}
          {slider('Visa','visa')}
        </div>
        <div>
          {slider('Flight Time','flightTime')}
          {slider('Transit','transit')}
          {slider('Women Safety','womenSafety')}
          {slider('Solo Safety','soloSafety')}
          <div className="mt-4">
            <label className="block text-sm font-medium mb-1">Target Month</label>
            <input type="number" min={1} max={12} value={month}
              onChange={(e)=>updateMonth(Number(e.target.value))}
              className="w-24 rounded border px-2 py-1 bg-white dark:bg-zinc-900"/>
          </div>
        </div>
      </div>

      <div className="mt-4">
        <div className="text-sm font-medium mb-2">Filter by tags</div>
        <div className="flex flex-wrap gap-2">
          {TAGS.map(t=>(
            <button key={t} onClick={()=>toggleTag(t)}
              className={`px-3 py-1 rounded-full border text-sm ${
                tags.includes(t)
                 ? 'bg-zinc-900 text-white dark:bg-white dark:text-black'
                 : 'bg-white dark:bg-zinc-900'
              }`}>
              {t}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}