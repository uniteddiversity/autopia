class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :admin, :type => Boolean
  field :paid, :type => Integer
  field :added_to_facebook_group, :type => Boolean
  field :desired_threshold, :type => Integer
  
  belongs_to :tier
  belongs_to :group    
  belongs_to :account
  belongs_to :mapplication
  
  validates_presence_of :account, :group
  validates_uniqueness_of :account, :scope => :group
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :group => group, :type => 'joined_group'
    
    if ENV['SMTP_ADDRESS']
      mail = Mail.new
      mail.to = account.email
      mail.from = "Huddl <team@huddl.tech>"
      mail.subject = "You're now a member of #{group.name}"
      
      account = self.account
      group = self.group
      
      if !account.sign_ins or account.sign_ins == 0
        action = %Q{<a href="http://#{ENV['DOMAIN']}/accounts/edit?sign_in_token=#{account.sign_in_token}&h=#{group.slug}">Click here to finish setting up your account and get involved with the co-creation!</a>}
      else
        action = %Q{<a href="http://#{ENV['DOMAIN']}/h/#{group.slug}?sign_in_token=#{account.sign_in_token}">Sign in to get involved with the co-creation!</a>}
      end      
      
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body "Hi #{account.firstname},<br /><br />You're now a member of #{group.name} on Huddl. #{action}<br /><br />Best,<br />Team Huddl" 
      end
      mail.html_part = html_part
      
      mail.deliver  
    end
  end     
  
  after_destroy do
    mapplication.destroy if mapplication
  end
  
  before_validation do
    self.desired_threshold = 1 if (self.desired_threshold and self.desired_threshold < 1)
  end
  
  def shifts
    Shift.where(:account_id => account_id, :rota_id.in => group.rota_ids)
  end
  
  def teamships
    Teamship.where(:account_id => account_id, :team_id.in => group.team_ids)
  end
  
  def tiership
    Tiership.find_by(:account_id => account_id, :group_id => group_id)
  end  
  
  def accomship
    Accomship.find_by(:account_id => account_id, :group_id => group_id)
  end    
  
  def transportships
    Transportship.where(:account_id => account_id, :group_id => group_id)
  end  
  
  def contribution
    c = 0
    if tiership
      c += tiership.tier.cost
    end
    if accomship
      c += accomship.accom.cost_per_person
    end    
    transportships.each { |transportship|
      c += transportship.transport.cost
    }
    c
  end
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :group_id => :lookup,      
      :mapplication_id => :lookup,
      :admin => :check_box,
      :paid => :number,
      :desired_threshold => :number,
      :added_to_facebook_group => :check_box,
    }
  end
      
end