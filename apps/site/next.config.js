const path = require("path");

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Lets a production build run in a separate folder while `next dev` is running
  distDir: process.env.NEXT_DIST_DIR || ".next",

  transpilePackages: ["three"],
  async redirects() {
    return [{ source: "/products", destination: "/work", permanent: true }];
  },
  // Monorepo: pin the root so Turbopack resolves `next` from this app's node_modules
  turbopack: { root: path.join(__dirname) },
};

module.exports = nextConfig;
