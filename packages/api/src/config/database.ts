import { PrismaClient } from '@prisma/client';
import Redis from 'ioredis';

// Construct DATABASE_URL if not provided
const getDatabaseUrl = (): string => {
  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }
  
  // Construct from individual RDS variables
  const host = process.env.RDS_HOST || 'localhost';
  const port = process.env.RDS_PORT || '5432';
  const database = process.env.RDS_DATABASE || 'appdb';
  const username = process.env.RDS_USERNAME || 'postgres';
  const password = process.env.RDS_PASSWORD || '';
  
  return `postgresql://${username}:${password}@${host}:${port}/${database}`;
};

// Set DATABASE_URL for Prisma if not already set
if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = getDatabaseUrl();
}

export const prisma = new PrismaClient();
export const redis = new Redis({
  host: process.env.REDIS_HOST || 'cache',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000);
    return delay;
  },
});

