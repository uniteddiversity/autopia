class Spend
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :item, :type => String
  field :amount, :type => Integer
  field :reimbursed, :type => Boolean

  belongs_to :group
  belongs_to :account
  
  validates_presence_of :group, :account
        
  def self.admin_fields
    {
      :item => :text,
      :amount => :number,
      :reimbursed => :check_box,
      :group_id => :lookup,      
      :account_id => :lookup      
    }
  end
  
  after_create do
    if ENV['SMTP_ADDRESS']
      account = self.account
      group = self.group
      
      mail = Mail.new
      mail.bcc = group.admin_emails
      mail.from = "Huddl <team@huddl.tech>"
      mail.subject = "#{account.name} listed an expense in #{group.name}"
      
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body %Q{Hi admins of #{group.name},<br /><br />#{account.name} listed an expense in #{group.name}. <a href="http://#{ENV['DOMAIN']}/h/#{group.slug}/spending">View spending</a><br /><br />Best,<br />Team Huddl}
      end
      mail.html_part = html_part       
      
      mail.deliver
    end           
  end    
    
end
