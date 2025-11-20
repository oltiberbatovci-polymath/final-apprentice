import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useParams, useNavigate } from 'react-router-dom'
import { format } from 'date-fns'
import { eventsApi, RSVPData } from '../services/api'
import toast from 'react-hot-toast'
import { useState } from 'react'

export default function EventDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  
  const [userName, setUserName] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const [response, setResponse] = useState<'going' | 'not_going' | 'maybe'>('going')

  const { data: event, isLoading: eventLoading } = useQuery({
    queryKey: ['event', id],
    queryFn: () => eventsApi.getById(id!),
    enabled: !!id,
  })

  const { data: rsvps, isLoading: rsvpsLoading } = useQuery({
    queryKey: ['rsvps', id],
    queryFn: () => eventsApi.getRSVPs(id!),
    enabled: !!id,
  })

  const rsvpMutation = useMutation({
    mutationFn: (data: RSVPData) => eventsApi.createRSVP(id!, data),
    onSuccess: () => {
      toast.success('RSVP submitted successfully!')
      queryClient.invalidateQueries({ queryKey: ['rsvps', id] })
      queryClient.invalidateQueries({ queryKey: ['event', id] })
      queryClient.invalidateQueries({ queryKey: ['events'] })
      setUserName('')
      setUserEmail('')
    },
    onError: () => {
      toast.error('Failed to submit RSVP')
    },
  })

  const deleteMutation = useMutation({
    mutationFn: () => eventsApi.delete(id!),
    onSuccess: () => {
      toast.success('Event deleted successfully!')
      queryClient.invalidateQueries({ queryKey: ['events'] })
      navigate('/')
    },
    onError: () => {
      toast.error('Failed to delete event')
    },
  })

  const handleDelete = () => {
    if (window.confirm('Are you sure you want to delete this event? This action cannot be undone.')) {
      deleteMutation.mutate()
    }
  }

  const handleRSVP = (e: React.FormEvent) => {
    e.preventDefault()
    if (!userName.trim() || !userEmail.trim()) {
      toast.error('Please fill in all fields')
      return
    }
    rsvpMutation.mutate({
      userId: '', // Will be created on backend
      userName: userName.trim(),
      userEmail: userEmail.trim(),
      response,
    })
  }

  if (eventLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  if (!event) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600 mb-4">Event not found</p>
        <button
          onClick={() => navigate('/')}
          className="text-indigo-600 hover:text-indigo-800"
        >
          Go back to events
        </button>
      </div>
    )
  }

  const goingCount = rsvps?.filter((r) => r.response === 'going').length || 0
  const maybeCount = rsvps?.filter((r) => r.response === 'maybe').length || 0
  const notGoingCount = rsvps?.filter((r) => r.response === 'not_going').length || 0

  return (
    <div className="max-w-4xl mx-auto">
      <button
        onClick={() => navigate('/')}
        className="text-indigo-600 hover:text-indigo-800 mb-6"
      >
        ← Back to Events
      </button>

      <div className="bg-white rounded-lg shadow-md p-8 mb-8">
        <div className="flex justify-between items-start mb-4">
          <h1 className="text-3xl font-bold text-gray-900">{event.title}</h1>
          <button
            onClick={handleDelete}
            disabled={deleteMutation.isPending}
            className="bg-red-600 text-white px-4 py-2 rounded-md font-medium hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {deleteMutation.isPending ? 'Deleting...' : 'Delete Event'}
          </button>
        </div>
        <p className="text-gray-600 mb-6">{event.description}</p>
        <div className="flex items-center space-x-4 text-sm text-gray-500">
          <span className="font-medium">
            📅 {format(new Date(event.date), 'MMMM d, yyyy')}
          </span>
          <span className="font-medium">
            🕐 {format(new Date(event.date), 'h:mm a')}
          </span>
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-8">
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">RSVP</h2>
          <form onSubmit={handleRSVP} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Name
              </label>
              <input
                type="text"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <input
                type="email"
                value={userEmail}
                onChange={(e) => setUserEmail(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Response
              </label>
              <select
                value={response}
                onChange={(e) => setResponse(e.target.value as any)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="going">Going</option>
                <option value="maybe">Maybe</option>
                <option value="not_going">Not Going</option>
              </select>
            </div>
            <button
              type="submit"
              disabled={rsvpMutation.isPending}
              className="w-full bg-indigo-600 text-white px-4 py-2 rounded-md font-medium hover:bg-indigo-700 disabled:opacity-50"
            >
              {rsvpMutation.isPending ? 'Submitting...' : 'Submit RSVP'}
            </button>
          </form>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            Attendees ({rsvps?.length || 0})
          </h2>
          <div className="space-y-2 mb-4">
            <div className="flex items-center justify-between text-sm">
              <span className="text-green-600">Going:</span>
              <span className="font-medium">{goingCount}</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-yellow-600">Maybe:</span>
              <span className="font-medium">{maybeCount}</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-red-600">Not Going:</span>
              <span className="font-medium">{notGoingCount}</span>
            </div>
          </div>
          <div className="border-t pt-4">
            {rsvpsLoading ? (
              <div className="text-center py-4">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-indigo-600 mx-auto"></div>
              </div>
            ) : rsvps && rsvps.length > 0 ? (
              <div className="space-y-2 max-h-64 overflow-y-auto">
                {rsvps.map((rsvp) => (
                  <div
                    key={rsvp.id}
                    className="flex items-center justify-between p-2 bg-gray-50 rounded"
                  >
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {rsvp.user.name}
                      </p>
                      <p className="text-xs text-gray-500">{rsvp.user.email}</p>
                    </div>
                    <span
                      className={`text-xs px-2 py-1 rounded-full ${
                        rsvp.response === 'going'
                          ? 'bg-green-100 text-green-800'
                          : rsvp.response === 'maybe'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-red-100 text-red-800'
                      }`}
                    >
                      {rsvp.response.replace('_', ' ')}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500 text-sm text-center py-4">
                No RSVPs yet
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

