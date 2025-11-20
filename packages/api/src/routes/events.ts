import express from 'express';
import { z } from 'zod';
import { prisma, redis } from '../config/database';
import { validateRequest } from '../middleware/validation';

const router = express.Router();

// Validation schemas
const createEventSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(1000),
  date: z.string().datetime(),
  createdBy: z.string().optional(),
  userName: z.string().min(1),
  userEmail: z.string().email(),
});

const rsvpSchema = z.object({
  userId: z.string().optional(),
  userName: z.string().min(1),
  userEmail: z.string().email(),
  response: z.enum(['going', 'not_going', 'maybe']),
});

// Cache keys
const getEventsCacheKey = () => 'events:list';
const getEventCacheKey = (id: string) => `events:${id}`;
const getRsvpCountCacheKey = (eventId: string) => `events:${eventId}:rsvp_count`;

// Helper: Get or create user
async function getOrCreateUser(email: string, name: string) {
  let user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    user = await prisma.user.create({
      data: { email, name },
    });
  } else if (user.name !== name) {
    user = await prisma.user.update({
      where: { email },
      data: { name },
    });
  }

  return user;
}

// POST /events - Create event
router.post('/', validateRequest(createEventSchema), async (req, res, next) => {
  try {
    const { title, description, date, createdBy, userName, userEmail } = req.body;

    // Get or create user
    const user = await getOrCreateUser(userEmail, userName);

    // Create event
    const event = await prisma.event.create({
      data: {
        title,
        description,
        date: new Date(date),
        createdBy: user.id,
      },
    });

    // Invalidate cache
    await redis.del(getEventsCacheKey());

    res.status(201).json(event);
  } catch (error: any) {
    next(error);
  }
});

// GET /events - List events (with caching)
router.get('/', async (req, res, next) => {
  try {
    const cacheKey = getEventsCacheKey();
    const cached = await redis.get(cacheKey);

    if (cached) {
      return res.json(JSON.parse(cached));
    }

    const events = await prisma.event.findMany({
      orderBy: { date: 'asc' },
      include: {
        _count: {
          select: { rsvps: true },
        },
      },
    });

    // Cache for 5 minutes
    await redis.setex(cacheKey, 300, JSON.stringify(events));

    res.json(events);
  } catch (error: any) {
    next(error);
  }
});

// GET /events/:id - Get event details
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const cacheKey = getEventCacheKey(id);
    const cached = await redis.get(cacheKey);

    if (cached) {
      return res.json(JSON.parse(cached));
    }

    const event = await prisma.event.findUnique({
      where: { id },
      include: {
        _count: {
          select: { rsvps: true },
        },
      },
    });

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    // Cache for 5 minutes
    await redis.setex(cacheKey, 300, JSON.stringify(event));

    res.json(event);
  } catch (error: any) {
    next(error);
  }
});

// POST /events/:id/rsvp - RSVP to event
router.post('/:id/rsvp', validateRequest(rsvpSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { userId, userName, userEmail, response } = req.body;

    // Check if event exists
    const event = await prisma.event.findUnique({
      where: { id },
    });

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    // Get or create user
    const user = await getOrCreateUser(userEmail, userName);

    // Create or update RSVP
    const rsvp = await prisma.rSVP.upsert({
      where: {
        eventId_userId: {
          eventId: id,
          userId: user.id,
        },
      },
      update: {
        response,
      },
      create: {
        eventId: id,
        userId: user.id,
        response,
      },
      include: {
        user: true,
      },
    });

    // Invalidate caches
    await redis.del(getEventCacheKey(id));
    await redis.del(getEventsCacheKey());
    await redis.del(getRsvpCountCacheKey(id));

    res.status(201).json(rsvp);
  } catch (error: any) {
    next(error);
  }
});

// GET /events/:id/rsvps - List RSVPs for an event
router.get('/:id/rsvps', async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if event exists
    const event = await prisma.event.findUnique({
      where: { id },
    });

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    const rsvps = await prisma.rSVP.findMany({
      where: { eventId: id },
      include: {
        user: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(rsvps);
  } catch (error: any) {
    next(error);
  }
});

// DELETE /events/:id - Delete event
router.delete('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if event exists
    const event = await prisma.event.findUnique({
      where: { id },
    });

    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }

    // Delete event (RSVPs will be cascade deleted due to schema)
    await prisma.event.delete({
      where: { id },
    });

    // Invalidate all related caches
    await redis.del(getEventCacheKey(id));
    await redis.del(getEventsCacheKey());
    await redis.del(getRsvpCountCacheKey(id));

    res.status(200).json({ message: 'Event deleted successfully' });
  } catch (error: any) {
    next(error);
  }
});

export default router;

