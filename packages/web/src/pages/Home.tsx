import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { format } from 'date-fns'
import { eventsApi, Event } from '../services/api'
import toast from 'react-hot-toast'

export default function Home() {
  const { data: events, isLoading, error } = useQuery<Event[]>({
    queryKey: ['events'],
    queryFn: eventsApi.getAll,
  })

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  if (error) {
    toast.error('Failed to load events')
    return (
      <div className="text-center py-12">
        <p className="text-red-600">Error loading events. Please try again.</p>
      </div>
    )
  }

  if (!events || events.length === 0) {
    return (
      <div className="text-center py-12">
        <h2 className="text-2xl font-bold text-gray-900 mb-4">No events yet</h2>
        <p className="text-gray-600 mb-6">Create your first event to get started!</p>
        <Link
          to="/events/new"
          className="inline-block bg-indigo-600 text-white px-6 py-3 rounded-md font-medium hover:bg-indigo-700"
        >
          Create Event
        </Link>
      </div>
    )
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Upcoming Events</h1>
        <Link
          to="/events/new"
          className="bg-indigo-600 text-white px-6 py-3 rounded-md font-medium hover:bg-indigo-700"
        >
          Create Event
        </Link>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {events.map((event) => (
          <Link
            key={event.id}
            to={`/events/${event.id}`}
            className="bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow p-6"
          >
            <h2 className="text-xl font-semibold text-gray-900 mb-2">
              {event.title}
            </h2>
            <p className="text-gray-600 text-sm mb-4 line-clamp-2">
              {event.description}
            </p>
            <div className="flex items-center justify-between text-sm text-gray-500">
              <span>{format(new Date(event.date), 'MMM d, yyyy h:mm a')}</span>
              <span className="bg-indigo-100 text-indigo-800 px-2 py-1 rounded-full">
                {event._count?.rsvps || 0} RSVPs
              </span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  )
}

