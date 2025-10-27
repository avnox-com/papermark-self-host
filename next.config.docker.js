// next.config.js override for Docker standalone builds
// Place this in stacks/projects/papermark/ directory

const nextConfig = {
  // Enable standalone output for Docker
  output: 'standalone',
  
  // Disable telemetry
  telemetry: false,
  
  // Image optimization
  images: {
    domains: [
      'localhost',
      // Add your domain
      process.env.NEXT_PUBLIC_BASE_URL?.replace('https://', '').replace('http://', ''),
      // S3/Storage domains
      's3.amazonaws.com',
      process.env.AWS_S3_BUCKET_NAME ? `${process.env.AWS_S3_BUCKET_NAME}.s3.amazonaws.com` : '',
      process.env.AWS_S3_BUCKET_NAME ? `${process.env.AWS_S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com` : '',
    ].filter(Boolean),
    unoptimized: process.env.NODE_ENV === 'development',
  },
  
  // Webpack configuration
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }
    return config;
  },
  
  // Environment variables validation
  env: {
    NEXT_PUBLIC_BASE_URL: process.env.NEXT_PUBLIC_BASE_URL,
  },
  
  // Experimental features
  experimental: {
    // Enable if needed
    // serverActions: true,
  },
  
  // Security headers
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on'
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload'
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN'
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block'
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin'
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()'
          }
        ],
      },
    ];
  },
};

module.exports = nextConfig;
