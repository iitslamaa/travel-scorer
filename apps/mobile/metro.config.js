// apps/mobile/metro.config.js
const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);

// 1) Watch the whole monorepo
config.watchFolders = [workspaceRoot];

// 2) Resolve modules from the repo root (avoid duplicate react/react-native)
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];

// 3) Allow importing TS/JS from packages/
config.resolver.sourceExts.push('cjs');

module.exports = config;