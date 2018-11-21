Geocoder.configure(
    # geocoding service
    lookup: :google,
    api_key: ENV['GOOGLE_API_KEY'],
    # geocoding service request timeout (in seconds)
    timeout: 10
)