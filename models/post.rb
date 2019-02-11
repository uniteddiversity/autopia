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
  
  def url
    case commentable_type
    when 'Team'
      team = commentable
      "#{ENV['BASE_URI']}/a/#{team.group.slug}/teams/#{team.id}#post-#{id}"
    when 'Activity'
      activity = commentable
      "#{ENV['BASE_URI']}/a/#{activity.group.slug}/activities/#{activity.id}#post-#{id}"
    when 'Mapplication'
      mapplication = commentable
      "#{ENV['BASE_URI']}/a/#{mapplication.group.slug}/applications"
    when 'Habit'
      habit = commentable
      "#{ENV['BASE_URI']}/habits/#{habit.id}#post-#{id}"
    end    
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
