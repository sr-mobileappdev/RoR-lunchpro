Stripe.api_key = ENV['STRIPE_SKEY']
Stripe.max_network_retries = 2
Stripe.open_timeout = 30 # seconds
Stripe.read_timeout = 80

