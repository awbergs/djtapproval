Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['DJTAPPROVAL_FB_APP_ID'], ENV['DJTAPPROVAL_FB_APP_SECRET'],
    scope: 'public_profile'
end
