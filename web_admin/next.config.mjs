/** @type {import('next').NextConfig} */
const nextConfig = {
  async redirects() {
    return [
      {
        source: '/dashboard/routes/create',
        destination: '/dashboard/routes',
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
