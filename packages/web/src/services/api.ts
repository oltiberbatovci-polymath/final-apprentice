import axios from 'axios';

// Use relative URL /api for production (CloudFront routes /api/* to ALB)
// For local development, set VITE_API_URL=http://localhost:5000/api
const API_URL = import.meta.env.VITE_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export interface User {
  id: string;
  name: string;
  email: string;
}

export interface Event {
  id: string;
  title: string;
  description: string;
  date: string;
  createdBy: string;
  createdAt: string;
  _count?: {
    rsvps: number;
  };
}

export interface RSVP {
  id: string;
  eventId: string;
  userId: string;
  response: 'going' | 'not_going' | 'maybe';
  createdAt: string;
  user: User;
}

export interface CreateEventData {
  title: string;
  description: string;
  date: string;
  createdBy: string;
  userName: string;
  userEmail: string;
}

export interface RSVPData {
  userId: string;
  userName: string;
  userEmail: string;
  response: 'going' | 'not_going' | 'maybe';
}

// Events API
export const eventsApi = {
  getAll: async (): Promise<Event[]> => {
    const response = await api.get<Event[]>('/events');
    return response.data;
  },

  getById: async (id: string): Promise<Event> => {
    const response = await api.get<Event>(`/events/${id}`);
    return response.data;
  },

  create: async (data: CreateEventData): Promise<Event> => {
    const response = await api.post<Event>('/events', data);
    return response.data;
  },

  getRSVPs: async (eventId: string): Promise<RSVP[]> => {
    const response = await api.get<RSVP[]>(`/events/${eventId}/rsvps`);
    return response.data;
  },

  createRSVP: async (eventId: string, data: RSVPData): Promise<RSVP> => {
    const response = await api.post<RSVP>(`/events/${eventId}/rsvp`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/events/${id}`);
  },
};

export default api;

