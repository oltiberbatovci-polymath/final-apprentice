export default function Health() {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <h1 className="text-2xl font-bold text-green-600 mb-2">✓ Healthy</h1>
        <p className="text-gray-600">Web service is running</p>
        <p className="text-sm text-gray-500 mt-4">
          {new Date().toISOString()}
        </p>
      </div>
    </div>
  )
}

