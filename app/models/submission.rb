class Submission
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :approval, type: Boolean
  field :ip_address, type: String
  field :fb_uid, type: String

  def self.can_submit?(fb_uid)
    p 'IN CAN SUBMIT'
    p fb_uid
    if Rails.env.development?
      return !self.where(fb_uid: fb_uid).where(:created_at.gt => DateTime.current.utc - 1.minute).any?
    end
    return !self.where(fb_uid: fb_uid).where(:created_at.gt => Date.current).any?
  end

  def self.last_submission(fb_uid)
    return nil unless fb_uid.present?
    self.where(fb_uid: fb_uid).order(&:created_at).last
  end
end
