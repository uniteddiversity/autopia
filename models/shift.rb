class Shift
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account
  belongs_to :role
  belongs_to :rslot
  belongs_to :rota
  
  validates_presence_of :account, :role, :rslot, :rota
        
  def self.admin_fields
    {
      :account_id => :lookup,
      :role_id => :lookup,
      :rslot_id => :lookup,    
      :rota_id => :lookup      
    }
  end
  
  after_create do
    if ENV['SMTP_ADDRESS']
      shift = self
      account = shift.account
      group = rota.group
      
      mail = Mail.new
      mail.bcc = Account.where(:id.in => group.memberships.where(admin: true).pluck(:account_id)).pluck(:email)
      mail.from = "Huddl <team@huddl.tech>"
      mail.subject = "#{account.name} signed up for a #{shift.rota.name} shift in #{group.name}"
      
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body %Q{Hi admins of #{group.name},<br /><br />#{account.name} signed up for a #{shift.rota.name} shift in #{group.name}. <a href="http://#{ENV['DOMAIN']}/h/#{group.slug}/rotas">View rotas</a><br /><br />Best,<br />Team Huddl}
      end
      mail.html_part = html_part       
      
      mail.deliver
    end           
  end
    
end
