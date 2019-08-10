class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :subject, :type => String
  
  belongs_to :account, index: true, inverse_of: :posts_as_creator
  belongs_to :commentable, polymorphic: true, index: true

  has_many :subscriptions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :comment_reactions, :dependent => :destroy 
    
  after_create do
    commentable.subscribers.each { |account| subscriptions.create account: account }    
  end
  
  def self.commentable_types
    %w{Team Activity Mapplication Habit Account Feature Place}
  end  
  
  def url
    if commentable.is_a?(Team)
      team = commentable
      "#{ENV['BASE_URI']}/a/#{team.gathering.slug}/teams/#{team.id}#post-#{id}"
    elsif commentable.is_a?(Activity)
      activity = commentable
      "#{ENV['BASE_URI']}/a/#{activity.gathering.slug}/activities/#{activity.id}#post-#{id}"
    elsif commentable.is_a?(Mapplication)
      mapplication = commentable
      "#{ENV['BASE_URI']}/a/#{mapplication.gathering.slug}/mapplications/#{mapplication.id}#post-#{id}"
    elsif commentable.is_a?(Habit)
      habit = commentable
      "#{ENV['BASE_URI']}/habits/#{habit.id}#post-#{id}"
    elsif commentable.is_a?(Account)
      account = commentable
      "#{ENV['BASE_URI']}/u/#{account.username}#post-#{id}"      
    elsif commentable.is_a?(Feature)
      feature = commentable
      "#{ENV['BASE_URI']}/features/#{feature.id}"  
    elsif commentable.is_a?(Place)
      place = commentable
      "#{ENV['BASE_URI']}/places/#{place.id}"                  
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
