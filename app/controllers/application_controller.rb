class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :set_session
  before_filter :set_approval_ratio, only: [:index, :submitted]
  before_filter :validate_access, only: [:submitted]

  def index
    if session[:last_submission_id]
      @last_submission = Submission.find(session[:last_submission_id])
    else
      @last_submission = nil
    end
    @unique_votes = Submission.distinct(:ip_address).count
    @unique_approvals = Submission.where(approval: true).distinct(:ip_address).count
    @unique_disapprovals = Submission.where(approval: false).distinct(:ip_address).count
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

  def oauth
    auth_hash = request.env['omniauth.auth']
    fb_uid = auth_hash['uid']
    session[:uid] = fb_uid
    params_hash = request.env['omniauth.params']

    if Submission.can_submit?(fb_uid)
      approval_choice = params_hash["approval"]
      submission = Submission.create(approval: approval_choice == "1", ip_address: request.remote_ip, fb_uid: fb_uid)
      session[:last_submission_id] = submission.id
      flash[:notice] = "Your vote has been counted."
      flash[:approval] = approval_choice
      redirect_to root_url(submitted:approval_choice)
    else
      last_submission = Submission.last_submission(fb_uid)
      p "CANNOT SUBMIT"
      p "CANNOT SUBMIT"
      p "CANNOT SUBMIT"
      p "LAST SUBMISSION"
      p last_submission
      session[:last_submission_id] = last_submission.id if last_submission.present?
      flash[:alert] = 'You can only vote once every day. Come back tomorrow!'
      flash[:too] = "early"
      redirect_to root_url
    end
  end

  private

  def set_session
    @session_id = session[:uid]
  end

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
    unless session[:uid]
      redirect_to root_url
    end
  end
end
