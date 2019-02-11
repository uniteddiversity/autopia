class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :subject, :type => String
  
  belongs_to :account, index: true  
  belongs_to :commentable, polymorphic: true, index: true

  has_many :subscriptions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :comment_reactions, :dependent => :destroy 
    
  after_create do
    commentable.subscribers.each { |account| subscriptions.create account: account }    
  end
  
  def self.commentable_types
    %w{Team Activity Mapplication Habit}
  end  
  
  def self.admin_fields
    {      
      :id => {:type => :text, :edit => false},
      :subject => :text,
      :account_id => :lookup,
      :commentable_id => :text,
      :commentable_type => :select,
      :subscriptions => :collection,
      :comments => :collection
    }
  end
  
  def subscribers
    Account.where(:unsubscribed.ne => true).where(:id.in => subscriptions.pluck(:account_id))
  end
  
  def emails
    subscribers.pluck(:email)
  end
    
end
