class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account
  belongs_to :group
  belongs_to :membership
  belongs_to :team
  belongs_to :post

  field :body, :type => String 
  field :title, :type => String 
  
  validates_presence_of :body
  
  has_many :comment_likes, :dependent => :destroy
  has_many :options, :dependent => :destroy
  has_many :read_receipts, :dependent => :destroy

  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    if account
      notifications.create! :group => group, :type => 'commented'
    end
  end  
  
  before_validation do
    self.team = self.post.team if self.post
    self.group = self.team.group if self.team
    self.membership = self.group.memberships.find_by(account: self.account) if self.group and self.account and !self.membership
  end    
  
  def first_in_post?
    !post or post.new_record? or post.comments.order('created_at asc').first.id == self.id
  end

  def self.admin_fields
    {
      :body => :text_area,
      :title => :text,
      :account_id => :lookup,
      :group_id => :lookup,
      :membership_id => :lookup,
      :team_id => :lookup,
      :post_id => :lookup
    }
  end
    
end
