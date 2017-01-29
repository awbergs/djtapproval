class Submission
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :approval, type: Boolean
  field :ip_address, type: String
  field :submitted_at, type: DateTime
end
