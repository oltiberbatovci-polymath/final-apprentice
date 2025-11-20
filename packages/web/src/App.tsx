import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Home from './pages/Home'
import EventDetail from './pages/EventDetail'
import CreateEvent from './pages/CreateEvent'
import Health from './pages/Health'
import Layout from './components/Layout'

function App() {
  return (
    <Router>
      <Layout>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/health" element={<Health />} />
          <Route path="/events/:id" element={<EventDetail />} />
          <Route path="/events/new" element={<CreateEvent />} />
        </Routes>
      </Layout>
    </Router>
  )
}

export default App

