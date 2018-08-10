class Habit
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :public, :type => Boolean

  belongs_to :account
  
  has_many :habit_completions, :dependent => :destroy  
  has_many :habitships, :dependent => :destroy
  
  validates_presence_of :name
        
  def self.admin_fields
    {
      :name => :text,
      :public => :check_box,
      :account_id => :lookup
    }
  end
    
end
