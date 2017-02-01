task nightly_tweet: :environment do
  submissions = Submission.where(:created_at.gt => DateTime.current.utc - 1.day)
  if submissions.any?
    approval_percentage = ((submissions.where(approval: true).count / submissions.count.to_f)*100).round(2)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["DJTAPP_TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["DJTAPP_TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["DJTAPP_TWITTER_ACCESS_TOKEN"]
      config.access_token_secret = ENV["DJTAPP_TWITTER_ACCESS_SECRET"]
    end
    client.update("::Nightly Update:: @POTUS @realDonaldTrump approval rating is #{approval_percentage}%. What do you think? Be heard @ www.djtrumpapproval.com #politics")
  end
end
