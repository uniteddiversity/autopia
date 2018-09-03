class HabitCompletionLike
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :habit_completion
    
  validates_presence_of :account, :habit_completion
  validates_uniqueness_of :account, :scope => :habit_completion
          
  def self.admin_fields
    {
      :account_id => :lookup,
      :habit_completion_id => :lookup
    }
  end
    
end
