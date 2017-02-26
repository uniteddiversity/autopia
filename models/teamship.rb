class Teamship
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :team, index: true
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => team.group, :type => 'joined_team'
  end  
  
  def self.admin_fields
    {
      :account_id => :lookup,
      :team_id => :lookup
    }
  end
    
end
