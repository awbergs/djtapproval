class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :set_approval_ratio, only: [:index]

  def index
  end

  def save
    ip_address = request.remote_ip
    if Submission.can_submit?(ip_address)
      if validate_captcha
        flash[:notice] = 'Saved'
        Submission.create(approval: params[:approval] == "1", ip_address: request.remote_ip)
      else
        flash[:notice] = 'Invalid captcha'
      end
    else
      flash[:notice] = 'You must wait at least 24 hours between submissions.'
    end
    redirect_to root_url
  end

  private

  def set_approval_ratio
    submissions = Submission.where(:created_at.gt => DateTime.current.utc - 1.day)
    if submissions.any?
      @approval_percentage = ((submissions.where(approval: true).count / submissions.count.to_f)*100).round(2)
    else
      @approval_percentage = 50
    end
  end

  def validate_captcha
    response = HTTParty.post('https://www.google.com/recaptcha/api/siteverify', {
      body: {
        secret: ENV["TRUMPAPPROVAL_RECAPTCHA_SECRET"],
        response: params["g-recaptcha-response"],
        remoteip: request.remote_ip
      }
    })
    resp = JSON.parse response.body
    return resp["success"]
  end
end
