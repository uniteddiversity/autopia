class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :admin, :type => Boolean
  field :paid, :type => Integer
  field :added_to_facebook_group, :type => Boolean
  field :desired_threshold, :type => Integer
  
  belongs_to :tier
  belongs_to :group    
  belongs_to :account
  belongs_to :mapplication
  
  validates_presence_of :account, :group
  validates_uniqueness_of :account, :scope => :group
  
  before_validation do
    self.desired_threshold = 1 if (self.desired_threshold and self.desired_threshold < 1)
  end
  
  def shifts
    Shift.where(:account_id => account_id, :rota_id.in => group.rota_ids)
  end
  
  def teamships
    Teamship.where(:account_id => account_id, :team_id.in => group.team_ids)
  end
  
  def tiership
    Tiership.find_by(:account_id => account_id, :group_id => group_id)
  end  
  
  def accomship
    Accomship.find_by(:account_id => account_id, :group_id => group_id)
  end    
  
  def transportships
    Transportship.where(:account_id => account_id, :group_id => group_id)
  end  
  
  def contribution
    c = 0
    if tiership
      c += tiership.tier.cost
    end
    if accomship
      c += accomship.accom.cost_per_person
    end    
    transportships.each { |transportship|
      c += transportship.transport.cost
    }
    c
  end
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,      
      :mapplication_id => :lookup,
      :admin => :check_box,
      :paid => :number,
      :desired_threshold => :number,
      :added_to_facebook_group => :check_box,
    }
  end
      
end
