class HabitCompletion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, :type => Date
  field :comment, :type => String

  belongs_to :account, index: true
  belongs_to :habit, index: true
  
  has_many :habit_completion_likes, :dependent => :destroy
    
  validates_presence_of :date, :account, :habit
  validates_uniqueness_of :habit, :scope => [:account, :date]
  
  before_validation do
    self.account = self.habit.account if self.habit
  end    
        
  def self.admin_fields
    {
      :date => :date,
      :comment => :text,
      :account_id => :lookup,
      :habit_id => :lookup
    }
  end
  
#  has_many :notifications, as: :notifiable, dependent: :destroy
#  after_create do
#    if habit.public?
#      notifications.create! :circle => account, :type => 'completed_a_habit'    
#    end
#  end     
    
end
