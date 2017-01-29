class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :set_approval_ratio, only: [:index, :submitted]
  before_filter :validate_access, only: [:submitted]

  def index
    @last_submission = Submission.where(ip_address:request.remote_ip).last
    @unique_votes = Submission.distinct(:ip_address).count
    @unique_approvals = Submission.where(approval: true).distinct(:ip_address).count
    @unique_disapprovals = Submission.where(approval: false).distinct(:ip_address).count
  end

  def submitted
    @last_submission = Submission.where(ip_address:request.remote_ip).last
    @unique_votes = Submission.distinct(:ip_address).count
    @unique_approvals = Submission.where(approval: true).distinct(:ip_address).count
    @unique_disapprovals = Submission.where(approval: false).distinct(:ip_address).count
    render 'index'
  end

  def save
    ip_address = request.remote_ip
    valid = false
    if Submission.can_submit?(ip_address)
      if validate_captcha
        valid = true
        session[:validated] = true
        flash[:success] = 'Your vote has been counted. You can vote again in 24 hours.'
        Submission.create(approval: params[:approval] == "1", ip_address: request.remote_ip)
      else
        flash[:notice] = 'Invalid captcha'
      end
    else
      flash[:notice] = 'You must wait at least 24 hours between submissions.'
    end
    if valid
      redirect_to "/submitted?approval=#{params[:approval]}"
    else
      redirect_to root_url
    end
  end

  def heatmap
    timestamp = DateTime.current.utc - 1.day
    unique_approvals = Submission.where(approval: true)
      .where(:created_at.gte => timestamp)
      .distinct(:ip_address)
    @unique_approvals = unique_approvals.map {|ip| Geokit::Geocoders::IpGeocoder.geocode(ip)}
    unique_disapprovals = Submission.where(approval: false)
      .where(:created_at.gte => timestamp)
      .distinct(:ip_address)
    @unique_disapprovals = unique_disapprovals.map {|ip| Geokit::Geocoders::IpGeocoder.geocode(ip)}
  end

  private

  def set_approval_ratio
    @submissions = Submission.where(:created_at.gt => DateTime.current.utc - 1.day)
    if @submissions.any?
      @approval_percentage = ((@submissions.where(approval: true).count / @submissions.count.to_f)*100).round(2)
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

  def validate_access
    unless session[:validated]
      redirect_to root_url
    end
  end
end
