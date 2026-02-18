import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Transpile our shared workspace package so Vercel can bundle it
  transpilePackages: ['@travel-af/shared', '@travel-af/domain'],

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
