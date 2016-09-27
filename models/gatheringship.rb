class Gatheringship
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :paid, :type => Integer

  belongs_to :account
  belongs_to :gathering
  
  def shifts
    Shift.where(:account_id => account_id, :rota_id.in => gathering.rota_ids)
  end
  
  def teamships
    Teamship.where(:account_id => account_id, :team_id.in => gathering.team_ids)
  end
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :gathering_id => :lookup,
      :paid => :number
    }
  end
    
end
