// pages/api/health.ts or app/api/health/route.ts
// Add this to your Papermark source for Docker health checks

import { NextApiRequest, NextApiResponse } from 'next';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // Basic health check
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Check database connection (optional - may slow down health checks)
    // const prisma = new PrismaClient();
    // await prisma.$queryRaw`SELECT 1`;
    
    res.status(200).json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV,
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
}

// For App Router (Next.js 13+), use this instead:
// 
// export async function GET() {
//   try {
//     return Response.json({
//       status: 'ok',
//       timestamp: new Date().toISOString(),
//       uptime: process.uptime(),
//       environment: process.env.NODE_ENV,
//     });
//   } catch (error) {
//     return Response.json(
//       {
//         status: 'error',
//         timestamp: new Date().toISOString(),
//         error: error instanceof Error ? error.message : 'Unknown error',
//       },
//       { status: 503 }
//     );
//   }
// }
