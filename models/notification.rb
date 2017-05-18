class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, :type => String
  
  belongs_to :group, index: true
  belongs_to :notifiable, polymorphic: true, index: true
  
  validates_presence_of :type
  
  after_create do
    pusher_client = Pusher::Client.new(app_id: ENV['PUSHER_APP_ID'], key: ENV['PUSHER_KEY'], secret: ENV['PUSHER_SECRET'], cluster: ENV['PUSHER_CLUSTER'], encrypted: true)
    pusher_client.trigger("notifications.#{group.slug}", 'updated', {})
  end
  
  after_destroy do
    pusher_client = Pusher::Client.new(app_id: ENV['PUSHER_APP_ID'], key: ENV['PUSHER_KEY'], secret: ENV['PUSHER_SECRET'], cluster: ENV['PUSHER_CLUSTER'], encrypted: true)
    pusher_client.trigger("notifications.#{group.slug}", 'updated', {})    
  end
  
  before_validation do
    errors.add(:type, 'not found') unless Notification.types.include?(type)
  end
  
  def self.types
    %w{created_group applied joined_group joined_team created_spend created_activity signed_up_to_a_shift joined_tier joined_transport joined_accom interested_in_activity gave_verdict created_transport created_tier created_team created_accom created_rota scheduled_activity unscheduled_activity made_admin unadmined booked created_timetable cultivating_quality commented liked_a_comment left_group created_payment}  
  end
  
  def self.mailable_types
    %w{created_group applied joined_group created_team created_timetable created_activity created_rota created_tier created_accom created_transport created_spend commented}
  end
  
  after_create :send_email  
  def send_email
    if ENV['SMTP_ADDRESS']
      notification = self
      group = self.group
      bcc = (type == 'commented' ? notifiable.team.emails : group.emails)
      
      if Notification.mailable_types.include?(type) and bcc.length > 0
        mail = Mail.new
        mail.bcc = bcc
        mail.from = (type == 'commented' ? "#{ENV['SITE_TITLE']} <#{group.slug}+#{notifiable.post_id}@#{ENV['MAILGUN_DOMAIN']}>" : ENV['NOTIFICATION_EMAIL'])
        mail.subject = "[#{group.name}] #{Nokogiri::HTML(notification.sentence).text}"
            
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body %Q{
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">    
    <style>
      p, ul, ol, input, select, .form-control, body, blockquote { font-family: 'Raleway', 'Helvetica Neue', Helvetica, Arial, sans-serif }
      h1, h2, h3, h4, h5, h6, .h { font-family: 'Raleway', 'Helvetica Neue', Helvetica, Arial, sans-serif; text-transform: uppercase; font-weight: 900 }
      a, a:hover, a:focus { color: #CE2828 !important; }
    </style>    
  </head>
  <body>
    <h1 style="margin-top: 0"><a style="text-decoration: none" href="https://#{ENV['DOMAIN']}/h/#{group.slug}">#{group.name}</a></h1>
    <p>#{notification.sentence}. <a href="#{notification.link[1]}">#{notification.link[0]}</a></p>
    #{notification.more}
    <p>Best,<br />#{ENV['SIGNATURE']}</p>
    <p style="font-size: 12px;"><a style="color: #aaa !important" href="https://#{ENV['DOMAIN']}/accounts/edit">Edit your profile to stop these emails</a></p>
  </body>
</html>
          }
        end
        mail.html_part = html_part
      
        mail.deliver
      end
    end    
  end
  handle_asynchronously :send_email  
  
  def sentence    
    case type.to_sym
    when :created_group
      group = notifiable
      "<strong>#{group.account.name}</strong> created the group"    
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
    when :created_spend
      spend = notifiable
      "<strong>#{spend.account.name}</strong> spent #{self.group.currency_symbol}#{spend.amount} on <strong>#{spend.item}</strong>"
    when :created_activity
      activity = notifiable
      "<strong>#{activity.account.name}</strong> proposed the activity <strong>#{activity.name}</strong> under <strong>#{activity.timetable.name}</strong>"
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
      "<strong>#{accom.account.name}</strong> created the accommodation <strong>#{accom.name}</strong>"                  
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
    when :created_timetable
      timetable = notifiable
      "<strong>#{timetable.account.name}</strong> created the timetable <strong>#{timetable.name}</strong>"      
    when :cultivating_quality
      cultivation = notifiable
      "<strong>#{cultivation.account.name}</strong> is cultivating <strong>#{cultivation.quality.name}</strong>"                  
    when :commented
      comment = notifiable
      "<strong>#{comment.account.name}</strong> posted in <strong>#{comment.team.name}</strong>"                  
    when :liked_a_comment
      comment_like = notifiable
      "<strong>#{comment_like.account.name}</strong> liked <strong>#{comment_like.comment.account.name}'s</strong> comment in <strong>#{comment_like.team.name}</strong>"
    when :left_group
      account = notifiable
      "<strong>#{account.name}</strong> is no longer a member of #{self.group.name}"
    when :created_payment
      payment = notifiable
      "<strong>#{payment.account.name}</strong> made a payment of #{Group.currency_symbol(payment.currency)}#{payment.amount}"
    end
  end
  
  def link
    case type.to_sym
    when :created_group
      ['View group', "https://#{ENV['DOMAIN']}/h/#{group.slug}"]
    when :applied
      ['View applications', "https://#{ENV['DOMAIN']}/h/#{group.slug}/applications"]
    when :joined_group
      ['View members', "https://#{ENV['DOMAIN']}/h/#{group.slug}/members"]      
    when :joined_team
      ['View team', "https://#{ENV['DOMAIN']}/h/#{group.slug}/teams/#{notifiable.team_id}"]
    when :created_spend
      ['View budget', "https://#{ENV['DOMAIN']}/h/#{group.slug}/budget"]
    when :created_activity
      ['View timetable', "https://#{ENV['DOMAIN']}/h/#{group.slug}/timetables/#{notifiable.timetable_id}"]
    when :signed_up_to_a_shift
      ['View rotas', "https://#{ENV['DOMAIN']}/h/#{group.slug}/rotas/#{notifiable.rota_id}"]
    when :joined_tier
      ['View tiers', "https://#{ENV['DOMAIN']}/h/#{group.slug}/tiers"]    
    when :joined_transport
      ['View transport', "https://#{ENV['DOMAIN']}/h/#{group.slug}/transports"] 
    when :joined_accom
      ['View accommodation', "https://#{ENV['DOMAIN']}/h/#{group.slug}/accoms"]      
    when :interested_in_activity
      ['View timetable', "https://#{ENV['DOMAIN']}/h/#{group.slug}/timetables/#{notifiable.activity.timetable_id}"]  
    when :gave_verdict
      ['View applications', "https://#{ENV['DOMAIN']}/h/#{group.slug}/applications"]
    when :created_transport
      ['View transport', "https://#{ENV['DOMAIN']}/h/#{group.slug}/transports"] 
    when :created_tier
      ['View tiers', "https://#{ENV['DOMAIN']}/h/#{group.slug}/tiers"]    
    when :created_team
      ['View team', "https://#{ENV['DOMAIN']}/h/#{group.slug}/teams/#{notifiable.id}"]
    when :created_accom
      ['View accommodation', "https://#{ENV['DOMAIN']}/h/#{group.slug}/accoms"]      
    when :created_rota
      ['View rotas', "https://#{ENV['DOMAIN']}/h/#{group.slug}/rotas/#{notifiable.id}"]
    when :scheduled_activity
      ['View timetable', "https://#{ENV['DOMAIN']}/h/#{group.slug}/timetables/#{notifiable.timetable_id}"]  
    when :unscheduled_activity
      ['View timetable', "https://#{ENV['DOMAIN']}/h/#{group.slug}/timetables/#{notifiable.timetable_id}"]  
    when :made_admin
      ['View members', "https://#{ENV['DOMAIN']}/h/#{group.slug}/members"]      
    when :unadmined
      ['View members', "https://#{ENV['DOMAIN']}/h/#{group.slug}/members"]      
    when :booked
      ['View bookings', "https://#{ENV['DOMAIN']}/h/#{group.slug}/bookings"]  
    when :created_timetable
      ['View timetables', "https://#{ENV['DOMAIN']}/h/#{group.slug}/timetables/#{notifiable.id}"]      
    when :cultivating_quality
      ['View qualities', "https://#{ENV['DOMAIN']}/h/#{group.slug}/qualities"]
    when :commented
      ['View post', "https://#{ENV['DOMAIN']}/h/#{group.slug}/teams/#{notifiable.team_id}#post-#{notifiable.post_id}"]
    when :liked_a_comment
      ['View post', "https://#{ENV['DOMAIN']}/h/#{group.slug}/teams/#{notifiable.team_id}#post-#{notifiable.post_id}"]      
    when :left_group
      ['View members', "https://#{ENV['DOMAIN']}/h/#{group.slug}/members"]
    when :created_payment
      ['View budget', "https://#{ENV['DOMAIN']}/h/#{group.slug}/budget"]
    end
  end
  
  def more
    case type.to_sym
    when :commented
      comment = notifiable
      "<blockquote>#{comment.body.gsub("\n","<br />")}</blockquote>"
    end
  end
      
  
  def icon
    case type.to_sym
    when :created_group
      'fa-group'
    when :applied
      'fa-file-text-o'
    when :joined_group
      'fa-user-plus'      
    when :joined_team
      'fa-group'
    when :created_spend
      'fa-money'
    when :created_activity
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
    when :created_timetable
      'fa-table'   
    when :cultivating_quality
      'fa-star'  
    when :commented
      'fa-comment'       
    when :liked_a_comment
      'fa-thumbs-up' 
    when :left_group
      'fa fa-sign-out'
    when :created_payment
      'fa-money'      
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
