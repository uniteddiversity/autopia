class Teamship
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :team
           
  def self.admin_fields
    {
      :account_id => :lookup,
      :team_id => :lookup
    }
  end
  
  after_create do
    if ENV['SMTP_ADDRESS']
      teamship = self
      account = teamship.account
      team = teamship.team
      group = team.group
      
      mail = Mail.new
      mail.bcc = Account.where(:id.in => group.memberships.where(admin: true).pluck(:account_id)).pluck(:email)
      mail.from = "Huddl <team@huddl.tech>"
      mail.subject = "#{account.name} joined the #{team.name} team in #{group.name}"
      
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body %Q{Hi admins of #{group.name},<br /><br />#{account.name} joined the #{team.name} team in #{group.name}. <a href="http://#{ENV['DOMAIN']}/h/#{group.slug}/teams">View teams</a><br /><br />Best,<br />Team Huddl}
      end
      mail.html_part = html_part       
      
      mail.deliver
    end           
  end  
    
end
