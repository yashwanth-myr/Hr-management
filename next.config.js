require('dotenv').config()

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['images.unsplash.com']
  },
  webpack: (config, { isServer }) => {
    // Fixes npm packages that depend on 'fs' module
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        crypto: false,
        pg: false,
        'pg-pool': false,
        'pg-native': false,
      };
      
      // Exclude server-only modules from client bundle
      config.externals = config.externals || [];
      config.externals.push({
        pg: 'pg',
        'pg-pool': 'pg-pool',
        'pg-native': 'pg-native',
      });
    }
    return config;
  },
  env: {
    DATABASE_URL: process.env.DATABASE_URL,
    DB_HOST: process.env.DB_HOST,
    DB_PORT: process.env.DB_PORT,
    DB_NAME: process.env.DB_NAME,
    DB_USER: process.env.DB_USER,
    DB_PASSWORD: process.env.DB_PASSWORD,
  }
}

module.exports = nextConfig