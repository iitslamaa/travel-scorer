import path from "path";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Ensure Turbopack uses THIS app as the root (fixes monorepo runtime issues)
  turbopack: {
    // Point Turbopack to monorepo root so it can resolve next + lockfile correctly
    root: path.resolve(__dirname, "../../"),
  },

  // Transpile shared workspace packages
  transpilePackages: ['@travel-af/shared', '@travel-af/domain'],

  // Allow importing code from outside this app's directory (monorepo)
  experimental: {
    externalDir: true,
  },

  // Use remotePatterns instead of deprecated images.domains
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'flagcdn.com',
      },
    ],
  },

  // Produce smaller, self-contained server build
  output: 'standalone',
};

export default nextConfig;
