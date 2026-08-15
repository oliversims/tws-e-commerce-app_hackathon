/** @type {import('next').NextConfig} */

// Baseline security headers. The session cookie is httpOnly, so the main
// residual XSS risk is script injection reading page state or exfiltrating
// data -- CSP is the control that addresses it.
//
// 'unsafe-inline' / 'unsafe-eval' on script-src are required by Next.js 14's
// inlined hydration bootstrap. Tightening this to a nonce-based policy is the
// natural follow-up; it needs every inline <script> to carry the nonce.
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: blob:",
      "font-src 'self' data:",
      "connect-src 'self'",
      "frame-ancestors 'none'",
      "form-action 'self'",
      "base-uri 'self'",
      "object-src 'none'",
    ].join('; '),
  },
  // Clickjacking. frame-ancestors above covers modern browsers; this is the
  // legacy equivalent.
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'X-DNS-Prefetch-Control', value: 'off' },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
  },
];

const config = {
  output: 'standalone',
  swcMinify: true,
  poweredByHeader: false,
  async headers() {
    return [
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },
};

module.exports = config;
