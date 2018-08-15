class Habit
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :public, :type => Boolean
  field :o, :type => Integer
  
  belongs_to :account
  
  has_many :habit_completions, :dependent => :destroy  

  has_many :posts, :as => :commentable, :dependent => :destroy
  has_many :subscriptions, :as => :commentable, :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :comment_likes, :as => :commentable, :dependent => :destroy  
  
  validates_presence_of :name
        
  def self.admin_fields
    {
      :name => :text,
      :o => :number,
      :public => :check_box,
      :account_id => :lookup
    }
  end
  
  def subscribers
    [account]
  end
    
end
