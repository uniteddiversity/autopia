class HabitCompletion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, :type => Date

  belongs_to :account
  belongs_to :habit
    
  validates_presence_of :date, :account, :habit
  validates_uniqueness_of :habit, :scope => [:account, :date]
  
  before_validation do
    self.account = self.habit.account if self.habit
  end    
        
  def self.admin_fields
    {
      :date => :date,
      :account_id => :lookup,
      :habit_id => :lookup
    }
  end
    
end
