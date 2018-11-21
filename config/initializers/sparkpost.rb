SparkPostRails.configure do |c|
  c.api_key = ENV['SPARKPOST_KEY']
  c.sandbox = false
  c.transactional = true
  c.inline_css = true
  c.html_content_only = true
  c.track_opens = true
end


# c.sandbox = true                                # default: false
# c.track_opens = true                            # default: false
# c.track_clicks = true                           # default: false
# c.return_path = 'BOUNCE-EMAIL@YOUR-DOMAIN.COM'  # default: nil
# c.campaign_id = 'YOUR-CAMPAIGN'                 # default: nil
# c.transactional = true                          # default: false
# c.ip_pool = "MY-POOL"                           # default: nil
# c.inline_css = true                             # default: false
# c.html_content_only = true                      # default: false
# c.subaccount = "123"                            # default: nil
