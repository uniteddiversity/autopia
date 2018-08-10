class Habitship
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :habit
  belongs_to :group  
  belongs_to :account  
  belongs_to :membership
    
  validates_presence_of :habit, :account, :group, :membership
  validates_uniqueness_of :habit, :scope => [:account, :group, :membership]
    
  before_validation do
  	self.account = self.habit.account if self.habit
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end  
        
  def self.admin_fields
    {
      :habit_id => :lookup,
      :group_id => :lookup,
      :account_id => :lookup,
      :membership_id => :lookup,
    }
  end
    
end
