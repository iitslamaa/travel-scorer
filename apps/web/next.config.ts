import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Transpile our shared workspace packages so Next/Vercel can bundle them
  transpilePackages: [
    'react-native',
    'react-native-web',
    '@travel-af/data',
    '@travel-af/ui',
  ],

  // Allow importing code from outside this app's directory (monorepo)
  experimental: {
    externalDir: true,
  },

  // Allow Next/Image to optimize external flags
  images: {
    domains: ['flagcdn.com'],
  },

  // Produce smaller, self-contained server build (good default on Vercel)
  output: 'standalone',
};

export default nextConfig;
