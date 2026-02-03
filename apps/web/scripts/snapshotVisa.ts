import { fetchVisaFromWikipedia } from '@/lib/providers/visa';
import fs from 'fs/promises';
import path from 'path';

async function run() {
  const map = await fetchVisaFromWikipedia();
  const obj = Object.fromEntries(map.entries());

  const outPath = path.join(
    process.cwd(),
    'data',
    'snapshots',
    'visa_us_citizens.json'
  );

  await fs.mkdir(path.dirname(outPath), { recursive: true });

  await fs.writeFile(outPath, JSON.stringify(obj, null, 2));
  console.log('✅ Visa snapshot written:', outPath);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});