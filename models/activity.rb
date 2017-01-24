class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account
  belongs_to :space
  belongs_to :tslot
  belongs_to :group
  
  field :description, :type => String
  
  validates_presence_of :account, :space, :tslot, :group
        
  def self.admin_fields
    {
      :description => :text_area,
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
