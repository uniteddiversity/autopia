class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :paid, :type => Integer
  field :added_to_facebook_group, :type => Boolean
  
  belongs_to :group    
  belongs_to :account, index: true, class_name: "Account", inverse_of: :memberships
  belongs_to :mapplication
  
  validates_presence_of :account, :group
  validates_uniqueness_of :account, :scope => :group
  
  def shifts
    Shift.where(:account_id => account_id, :rota_id.in => group.rota_ids)
  end
  
  def teamships
    Teamship.where(:account_id => account_id, :team_id.in => group.team_ids)
  end
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,      
      :mapplication_id => :lookup,
      :paid => :number,
      :added_to_facebook_group => :check_box,
    }
  end
    
end
