class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, :type => String
  
  belongs_to :group  
  belongs_to :notifiable, polymorphic: true
  
  validates_presence_of :group, :notifiable, :type
  
  before_validation do
    errors.add(:type, 'not found') unless Notification.types.include?(type)
  end
  
  def self.types
    %w{joined_team listed_spend listed_activity signed_up_to_a_shift applied joined_group joined_tier joined_transport joined_accom interested_in_activity gave_verdict}
  end
  
  after_create do
    if ENV['SMTP_ADDRESS']
      notification = self
      group = self.group
      
      mail = Mail.new
      mail.bcc = group.admin_emails
      mail.from = "Huddl <team@huddl.tech>"
      mail.subject = "[#{group.name}] #{Nokogiri::HTML(notification.sentence).text}"
            
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body %Q{<h2 style="margin-top: 0"><a href="http://#{ENV['DOMAIN']}/h/#{group.slug}">#{group.name}</a></h2>#{notification.sentence}. <a href="#{notification.link[1]}">#{notification.link[0]}</a><br /><br />Best,<br />Team Huddl<br /><br /><a style="font-size: 12px; color: #ccc" href="http://#{ENV['DOMAIN']}/accounts/edit">Stop these emails</a>}
      end
      mail.html_part = html_part
      
      mail.deliver  
    end    
  end
  
  def sentence    
    case type.to_sym
    when :joined_team
      teamship = notifiable
      account = teamship.account
      team = teamship.team
      "<strong>#{account.name}</strong> joined the <strong>#{team.name}</strong> team"
    when :listed_spend
      spend = notifiable
      account = spend.account
      "<strong>#{account.name}</strong> listed an expense: <strong>#{spend.item}</strong>"
    when :listed_activity
      activity = notifiable
      account = activity.account
      "<strong>#{account.name}</strong> listed an activity: <strong>#{activity.name}</strong>"
    when :signed_up_to_a_shift
      shift = notifiable
      rota = shift.rota
      account = shift.account
      "<strong>#{account.name}</strong> signed up for a <strong>#{rota.name}</strong> shift"
    when :applied
      mapplication = notifiable
      account = mapplication.account
      "<strong>#{account.name}</strong> applied"
    when :joined_group
      membership = notifiable
      account =  membership.account
      mapplication = membership.mapplication
      if mapplication
        if mapplication.processed_by
          "<strong>#{account.name}</strong> was accepted by <strong>#{mapplication.processed_by.name}</strong>"
        else
          "<strong>#{account.name}</strong> was automatically accepted"
        end
      else
        "<strong>#{account.name}</strong> was added"
      end
    when :joined_tier
      tiership = notifiable
      account = tiership.account
      tier = tiership.tier
      "<strong>#{account.name}</strong> joined the <strong>#{tier.name}</strong> tier"      
    when :joined_transport
      transportship = notifiable
      account = transportship.account
      transport = transportship.transport
      "<strong>#{account.name}</strong> joined the <strong>#{transport.name}</strong> transport"   
    when :joined_accom
      accomship = notifiable
      account = accomship.account
      accom = accomship.accom
      "<strong>#{account.name}</strong> joined the <strong>#{accom.name}</strong> accommodation"        
    when :interested_in_activity
      attendance = notifiable
      account = attendance.account
      activity = attendance.activity
      "<strong>#{account.name}</strong> is interested in <strong>#{activity.name}</strong>"
    when :gave_verdict
      verdict = notifiable
      "<strong>#{verdict.account.name}</strong> #{verdict.ed} <strong>#{verdict.mapplication.account.name}</strong>"
    end
  end
  
  def link
    case type.to_sym
    when :joined_team
      ['View teams', "http://#{ENV['DOMAIN']}/h/#{group.slug}/teams"]
    when :listed_spend
      ['View spending', "http://#{ENV['DOMAIN']}/h/#{group.slug}/spending"]
    when :listed_activity
      ['View timetable', "http://#{ENV['DOMAIN']}/h/#{group.slug}/timetable"]
    when :signed_up_to_a_shift
      ['View rotas', "http://#{ENV['DOMAIN']}/h/#{group.slug}/rotas"]
    when :applied
      ['View applications', "http://#{ENV['DOMAIN']}/h/#{group.slug}/applications"]
    when :joined_group
      ['View members', "http://#{ENV['DOMAIN']}/h/#{group.slug}"]
    when :joined_tier
      ['View tiers', "http://#{ENV['DOMAIN']}/h/#{group.slug}/tiers"]    
    when :joined_transport
      ['View transport', "http://#{ENV['DOMAIN']}/h/#{group.slug}/transports"] 
    when :joined_accom
      ['View accommodation', "http://#{ENV['DOMAIN']}/h/#{group.slug}/accoms"]      
    when :interested_in_activity
      ['View timetable', "http://#{ENV['DOMAIN']}/h/#{group.slug}/timetable"]  
    when :gave_verdict
      ['View applications', "http://#{ENV['DOMAIN']}/h/#{group.slug}/applications"]
    end
  end
  
  def icon
    case type.to_sym
    when :joined_team
      'fa-group'
    when :listed_spend
      'fa-money'
    when :listed_activity
      'fa-paper-plane'
    when :signed_up_to_a_shift
      'fa-hand-paper-o'
    when :applied
      'fa-file-text-o'
    when :joined_group
      'fa-user-plus'
    when :joined_tier
      'fa-align-justify'
    when :joined_transport
      'fa-bus'
    when :joined_accom
      'fa-home'
    when :interested_in_activity
      'fa-thumbs-up'
    when :gave_verdict
      'fa-gavel'
    end    
  end

        
  def self.admin_fields
    {
      :group_id => :lookup,
      :notifiable_type => :text,
      :notifiable_id => :text,
      :type => :text
    }
  end
    
end
