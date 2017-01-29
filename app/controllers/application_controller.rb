class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :set_approval_ratio

  def index
  end

  def save
    #need to restrict voting to once per N period (1day, 1month?)
    Submission.create(approval: params[:approval] == "1", ip_address: request.remote_ip)
    flash[:notice] = 'Saved'
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
end
