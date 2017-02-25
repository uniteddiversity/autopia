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
    %w{applied joined_group joined_team listed_spend listed_activity signed_up_to_a_shift joined_tier joined_transport joined_accom interested_in_activity gave_verdict created_transport created_tier created_team created_accom created_rota scheduled_activity unscheduled_activity made_admin unadmined booked}
  end
  
  def self.mailable_types
    %w{applied joined_group listed_activity created_transport created_tier created_team created_accom created_rota listed_spend}
  end
  
  after_create do
    if ENV['SMTP_ADDRESS']
      notification = self
      group = self.group
      
      if Notification.mailable_types.include?(type)
        mail = Mail.new
        mail.bcc = group.emails
        mail.from = "Huddl <team@huddl.tech>"
        mail.subject = "[#{group.name}] #{Nokogiri::HTML(notification.sentence).text}"
            
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body %Q{<h2 style="margin-top: 0"><a href="http://#{ENV['DOMAIN']}/h/#{group.slug}">#{group.name}</a></h2>#{notification.sentence}. <a href="#{notification.link[1]}">#{notification.link[0]}</a><br /><br />Best,<br />Team Huddl<br /><br /><a style="font-size: 12px; color: #aaa" href="http://#{ENV['DOMAIN']}/accounts/edit">Stop these emails</a>}
        end
        mail.html_part = html_part
      
        mail.deliver  
      end
    end    
  end
  
  def sentence    
    case type.to_sym
    when :applied
      mapplication = notifiable
      "<strong>#{mapplication.account.name}</strong> applied"
    when :joined_group
      membership = notifiable
      mapplication = membership.mapplication
      if mapplication
        if mapplication.processed_by
          "<strong>#{membership.account.name}</strong> was accepted by <strong>#{mapplication.processed_by.name}</strong>"
        else
          "<strong>#{membership.account.name}</strong> was automatically accepted"
        end
      elsif membership.added_by
        "<strong>#{membership.account.name}</strong> was added by #{membership.added_by.name}"
      end      
    when :joined_team
      teamship = notifiable
      "<strong>#{teamship.account.name}</strong> joined the <strong>#{teamship.team.name}</strong> team"
    when :listed_spend
      spend = notifiable
      "<strong>#{spend.account.name}</strong> spent £#{spend.amount} on <strong>#{spend.item}</strong>"
    when :listed_activity
      activity = notifiable
      "<strong>#{activity.account.name}</strong> listed the activity <strong>#{activity.name}</strong>"
    when :signed_up_to_a_shift
      shift = notifiable
      "<strong>#{shift.account.name}</strong> signed up for a <strong>#{shift.rota.name}</strong> shift"
    when :joined_tier
      tiership = notifiable
      "<strong>#{tiership.account.name}</strong> joined the <strong>#{tiership.tier.name}</strong> tier"      
    when :joined_transport
      transportship = notifiable
      "<strong>#{transportship.account.name}</strong> joined the <strong>#{transportship.transport.name}</strong> transport"   
    when :joined_accom
      accomship = notifiable
      "<strong>#{accomship.account.name}</strong> joined the <strong>#{accomship.accom.name}</strong> accommodation"        
    when :interested_in_activity
      attendance = notifiable
      "<strong>#{attendance.account.name}</strong> is interested in <strong>#{attendance.activity.name}</strong>"
    when :gave_verdict
      verdict = notifiable
      "<strong>#{verdict.account.name}</strong> #{verdict.ed} <strong>#{verdict.mapplication.account.name}</strong>"
    when :created_transport
      transport = notifiable
      "<strong>#{transport.account.name}</strong> created the transport <strong>#{transport.name}</strong>"
    when :created_tier
      tier = notifiable
      "<strong>#{tier.account.name}</strong> created the tier <strong>#{tier.name}</strong>"      
    when :created_team
      team = notifiable
      "<strong>#{team.account.name}</strong> created the team <strong>#{team.name}</strong>"            
    when :created_accom
      accom = notifiable
      "<strong>#{accom.account.name}</strong> craeted the accommodation <strong>#{accom.name}</strong>"                  
    when :created_rota
      rota = notifiable
      "<strong>#{rota.account.name}</strong> created the rota <strong>#{rota.name}</strong>"                        
    when :scheduled_activity
      activity = notifiable
      "<strong>#{activity.scheduled_by.name}</strong> scheduled the activity <strong>#{activity.name}</strong>"
    when :unscheduled_activity
      activity = notifiable
      "<strong>#{activity.scheduled_by.name}</strong> unscheduled the activity <strong>#{activity.name}</strong>"
    when :made_admin
      membership = notifiable
      "<strong>#{membership.account.name}</strong> was made an admin by <strong>#{membership.admin_status_changed_by.name}</strong>"
    when :unadmined
      membership = notifiable
      "<strong>#{membership.account.name}</strong> was unadmined by <strong>#{membership.admin_status_changed_by.name}</strong>"      
    when :booked
      booking = notifiable
      "<strong>#{booking.account.name}</strong> booked <strong>#{booking.date}</strong>"      
    end
  end
  
  def link
    case type.to_sym
    when :applied
      ['View applications', "http://#{ENV['DOMAIN']}/h/#{group.slug}/applications"]
    when :joined_group
      ['View members', "http://#{ENV['DOMAIN']}/h/#{group.slug}"]      
    when :joined_team
      ['View teams', "http://#{ENV['DOMAIN']}/h/#{group.slug}/teams"]
    when :listed_spend
      ['View spending', "http://#{ENV['DOMAIN']}/h/#{group.slug}/spending"]
    when :listed_activity
      ['View timetable', "http://#{ENV['DOMAIN']}/h/#{group.slug}/timetable"]
    when :signed_up_to_a_shift
      ['View rotas', "http://#{ENV['DOMAIN']}/h/#{group.slug}/rotas"]
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
    when :created_transport
      ['View transport', "http://#{ENV['DOMAIN']}/h/#{group.slug}/transports"] 
    when :created_tier
      ['View tiers', "http://#{ENV['DOMAIN']}/h/#{group.slug}/tiers"]    
    when :created_team
      ['View teams', "http://#{ENV['DOMAIN']}/h/#{group.slug}/teams"]
    when :created_accom
      ['View accommodation', "http://#{ENV['DOMAIN']}/h/#{group.slug}/accoms"]      
    when :created_rota
      ['View rotas', "http://#{ENV['DOMAIN']}/h/#{group.slug}/rotas"]
    when :scheduled_activity
      ['View timetable', "http://#{ENV['DOMAIN']}/h/#{group.slug}/timetable"]  
    when :unscheduled_activity
      ['View timetable', "http://#{ENV['DOMAIN']}/h/#{group.slug}/timetable"]  
    when :made_admin
      ['View members', "http://#{ENV['DOMAIN']}/h/#{group.slug}"]      
    when :unadmined
      ['View members', "http://#{ENV['DOMAIN']}/h/#{group.slug}"]      
    when :booked
      ['View bookings', "http://#{ENV['DOMAIN']}/h/#{group.slug}/bookings"]  
    end
  end
  
  def icon
    case type.to_sym
    when :applied
      'fa-file-text-o'
    when :joined_group
      'fa-user-plus'      
    when :joined_team
      'fa-group'
    when :listed_spend
      'fa-money'
    when :listed_activity
      'fa-paper-plane'
    when :signed_up_to_a_shift
      'fa-hand-paper-o'
    when :joined_tier
      'fa-align-justify'
    when :joined_transport
      'fa-bus'
    when :joined_accom
      'fa-home'
    when :interested_in_activity
      'fa-thumbs-up'
    when :gave_verdict
      'fa-puzzle-piece'
    when :created_transport
      'fa-bus'
    when :created_tier
      'fa-align-justify'
    when :created_team
      'fa-group'
    when :created_accom
      'fa-home'
    when :created_rota
      'fa-table'
    when :scheduled_activity
      'fa-calendar-plus-o'
    when :unscheduled_activity
      'fa-calendar-minus-o'
    when :made_admin
      'fa-key'
    when :unadmined
      'fa-key'
    when :booked
      'fa-calendar'
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
