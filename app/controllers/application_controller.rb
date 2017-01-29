class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :set_approval_ratio, only: [:index]

  def index
  end

  def save
    ip_address = request.remote_ip
    if true #Submission.can_submit?(ip_address)
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
    total = Submission.count
    if total > 0
      @approval_ratio = ((Submission.where(approval: true).count / total.to_f)*100).round(2)
    else
      @approval_ratio = 0
    end
  end

  def validate_captcha
    response = HTTParty.post('https://www.google.com/recaptcha/api/siteverify', {
      body: {
        secret: '6LfCfRMUAAAAAAvqhVLyVaUVYx5cqho_yepO7oT-',
        response: params["g-recaptcha-response"],
        remoteip: request.remote_ip
      }
    })
    resp = JSON.parse response.body
    p resp
    p resp["success"]
    return resp["success"]
  end
end
