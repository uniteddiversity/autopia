class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
     
  belongs_to :account
  belongs_to :space
  belongs_to :tslot
  belongs_to :group
  
  field :name, :type => String
  field :description, :type => String
  field :image_uid, :type => String
  
  dragonfly_accessor :image
  
  validates_presence_of :name, :description, :account, :group
  
  has_many :attendances, :dependent => :destroy
        
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :image => :image,
      :account_id => :lookup,
      :space_id => :lookup,
      :tslot_id => :lookup,    
      :group_id => :lookup      
    }
  end
    
  after_create do
    if ENV['SMTP_ADDRESS']
      account = self.account
      group = self.group
      
      mail = Mail.new
      mail.bcc = group.admin_emails
      mail.from = "Huddl <team@huddl.tech>"
      mail.subject = "#{account.name} listed an activity in #{group.name}"
      
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body %Q{Hi admins of #{group.name},<br /><br />#{account.name} listed an activity in #{group.name}. <a href="http://#{ENV['DOMAIN']}/h/#{group.slug}/timetable">View timetable</a><br /><br />Best,<br />Team Huddl}
      end
      mail.html_part = html_part       
      
      mail.deliver
    end           
  end  
    
end
