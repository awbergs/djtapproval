class Submission
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :approval, type: Boolean
  field :ip_address, type: String

  def self.can_submit?(ip)
    if Rails.env.development?
      return true
    end
    return !self.where(ip_address: ip).where(:created_at.gt => DateTime.current.utc - 1.day).any?
  end
end
