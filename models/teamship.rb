class Teamship
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :team
           
  def self.admin_fields
    {
      :account_id => :lookup,
      :team_id => :lookup
    }
  end
    
end
