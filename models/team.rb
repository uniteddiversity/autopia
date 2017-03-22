class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  has_many :teamships, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :comment_likes, :dependent => :destroy
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'created_team'
  end      
  
  def members
    Account.where(:id.in => teamships.pluck(:account_id))
  end
  
  def emails
    Account.where(:stop_emails.ne => true).where(:id.in => teamships.pluck(:account_id)).pluck(:email)
  end    
        
  def self.admin_fields
    {
      :name => :text,
      :description => :wysiwyg,
      :group_id => :lookup,
      :account_id => :lookup,
      :teamships => :collection,
    }
  end
    
end
