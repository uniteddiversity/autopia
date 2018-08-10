class Habit
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :public, :type => Boolean
  field :o, :type => Integer
  
  belongs_to :account
  
  has_many :habit_completions, :dependent => :destroy  
  
  validates_presence_of :name
        
  def self.admin_fields
    {
      :name => :text,
      :o => :number,
      :public => :check_box,
      :account_id => :lookup
    }
  end
    
end
