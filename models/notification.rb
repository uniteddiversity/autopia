class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, :type => String
  
  belongs_to :circle, polymorphic: true, index: true
  belongs_to :notifiable, polymorphic: true, index: true
  
  def self.circle_types
    %w{Group Account}
  end
  
  validates_presence_of :type
    
  before_validation do
    errors.add(:type, 'not found') unless Notification.types.include?(type)
  end
  
  def self.types
    %w{created_group applied joined_group created_team created_timetable created_activity created_rota created_tier created_accom created_transport created_spend joined_team signed_up_to_a_shift joined_tier joined_transport joined_accom interested_in_activity gave_verdict scheduled_activity unscheduled_activity made_admin unadmined cultivating_quality commented reacted_to_a_comment left_group created_payment created_inventory_item mapplication_removed}
  end
  
  def self.mailable_types
    %w{created_group applied joined_group created_team created_timetable created_activity created_rota created_tier created_accom created_transport created_spend}
  end
    
  after_create :send_email  
  def send_email
    if ENV['SMTP_ADDRESS'] && Notification.mailable_types.include?(type) && circle.is_a?(Group)
      notification = self      
      circle = self.circle
      bcc = circle.emails
      
      if bcc.length > 0
        mail = Mail.new
        mail.bcc = bcc
        mail.from = ENV['NOTIFICATION_EMAIL']
        mail.subject = "[#{circle.name}] #{Nokogiri::HTML(notification.sentence).text}"
            
        content = ERB.new(File.read(Padrino.root('app/views/emails/notification.erb'))).result(binding)
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
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
      else
        "<strong>#{membership.account.name}</strong> joined the group"
      end
    when :joined_team
      teamship = notifiable
      "<strong>#{teamship.account.name}</strong> joined the <strong>#{teamship.team.name}</strong> team"
    when :created_spend
      spend = notifiable
      "<strong>#{spend.account.name}</strong> spent #{spend.group.currency_symbol}#{spend.amount} on <strong>#{spend.item}</strong>"
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
    when :created_timetable
      timetable = notifiable
      "<strong>#{timetable.account.name}</strong> created the timetable <strong>#{timetable.name}</strong>"      
    when :cultivating_quality
      cultivation = notifiable
      "<strong>#{cultivation.account.name}</strong> is cultivating <strong>#{cultivation.quality.name}</strong>"                  
    when :commented
      comment = notifiable
      if comment.commentable.is_a?(Mapplication)
        "<strong>#{comment.account.name}</strong> commented on <strong>#{comment.commentable.account.name}</strong>'s application"                  
      else
        if comment.post.comments.count == 1
          "<strong>#{comment.account.name}</strong> started a thread <strong>#{comment.commentable.name}#{if comment.post.subject; "/#{comment.post.subject}"; end}</strong>"                  
        else
          "<strong>#{comment.account.name}</strong> replied to <strong>#{comment.commentable.name}#{if comment.post.subject; "/#{comment.post.subject}"; end}</strong>"                  
        end
      end      
    when :reacted_to_a_comment
      comment_reaction = notifiable
      "<strong>#{comment_reaction.account.name}</strong> reacted with #{comment_reaction.body} to <strong>#{comment_reaction.comment.account.name}'s</strong> comment in <strong>#{comment_reaction.commentable.name}#{if comment_reaction.comment.post.subject; "/#{comment_reaction.comment.post.subject}"; end}</strong>"
    when :left_group
      account = notifiable
      "<strong>#{account.name}</strong> is no longer a member of #{circle.name}"
    when :created_payment
      payment = notifiable
      "<strong>#{payment.account.name}</strong> made a payment of #{Group.currency_symbol(payment.currency)}#{payment.amount}"
    when :created_inventory_item
      inventory_item = notifiable
      "<strong>#{inventory_item.account.name}</strong> listed the item <strong>#{inventory_item.name}</strong>"
    when :mapplication_removed
      account = notifiable
      "<strong>#{account.name}</strong>'s application was deleted"
    end
  end
  
  def link
    case type.to_sym
    when :created_group
      ['View group', "#{ENV['BASE_URI']}/a/#{circle.slug}"]
    when :applied
      ['View applications', "#{ENV['BASE_URI']}/a/#{circle.slug}/applications"]
    when :joined_group
      ['View members', "#{ENV['BASE_URI']}/a/#{circle.slug}/members"]      
    when :joined_team
      ['View team', "#{ENV['BASE_URI']}/a/#{circle.slug}/teams/#{notifiable.team_id}"]
    when :created_spend
      ['View budget', "#{ENV['BASE_URI']}/a/#{circle.slug}/budget"]
    when :created_activity
      ['View timetable', "#{ENV['BASE_URI']}/a/#{circle.slug}/activities/#{notifiable.id}"]
    when :signed_up_to_a_shift
      ['View rotas', "#{ENV['BASE_URI']}/a/#{circle.slug}/rotas/#{notifiable.rota_id}"]
    when :joined_tier
      ['View tiers', "#{ENV['BASE_URI']}/a/#{circle.slug}/tiers"]    
    when :joined_transport
      ['View transport', "#{ENV['BASE_URI']}/a/#{circle.slug}/transports"] 
    when :joined_accom
      ['View accommodation', "#{ENV['BASE_URI']}/a/#{circle.slug}/accoms"]      
    when :interested_in_activity
      ['View timetable', "#{ENV['BASE_URI']}/a/#{circle.slug}/activities/#{notifiable.activity_id}"]  
    when :gave_verdict
      ['View applications', "#{ENV['BASE_URI']}/a/#{circle.slug}/applications"]
    when :created_transport
      ['View transport', "#{ENV['BASE_URI']}/a/#{circle.slug}/transports"] 
    when :created_tier
      ['View tiers', "#{ENV['BASE_URI']}/a/#{circle.slug}/tiers"]    
    when :created_team
      ['View team', "#{ENV['BASE_URI']}/a/#{circle.slug}/teams/#{notifiable.id}"]
    when :created_accom
      ['View accommodation', "#{ENV['BASE_URI']}/a/#{circle.slug}/accoms"]      
    when :created_rota
      ['View rotas', "#{ENV['BASE_URI']}/a/#{circle.slug}/rotas/#{notifiable.id}"]
    when :scheduled_activity
      ['View timetable', "#{ENV['BASE_URI']}/a/#{circle.slug}/activities/#{notifiable.id}"]  
    when :unscheduled_activity
      ['View timetable', "#{ENV['BASE_URI']}/a/#{circle.slug}/activities/#{notifiable.id}"]  
    when :made_admin
      ['View members', "#{ENV['BASE_URI']}/a/#{circle.slug}/members"]      
    when :unadmined
      ['View members', "#{ENV['BASE_URI']}/a/#{circle.slug}/members"]      
    when :created_timetable
      ['View timetables', "#{ENV['BASE_URI']}/a/#{circle.slug}/timetables/#{notifiable.id}"]      
    when :cultivating_quality
      ['View qualities', "#{ENV['BASE_URI']}/a/#{circle.slug}/qualities"]
    when :commented
      ['View post', "#{ENV['BASE_URI']}/a/#{circle.slug}/#{notifiable.commentable_type.underscore.pluralize}/#{notifiable.commentable_id}#post-#{notifiable.post_id}"]
    when :reacted_to_a_comment
      ['View post', "#{ENV['BASE_URI']}/a/#{circle.slug}/#{notifiable.commentable_type.underscore.pluralize}/#{notifiable.commentable_id}#post-#{notifiable.post_id}"]
    when :left_group
      ['View members', "#{ENV['BASE_URI']}/a/#{circle.slug}/members"]
    when :created_payment
      ['View budget', "#{ENV['BASE_URI']}/a/#{circle.slug}/budget"]
    when :created_inventory_item
      ['View inventory', "#{ENV['BASE_URI']}/a/#{circle.slug}/inventory"]
    when :mapplication_removed
      ['View applications', "#{ENV['BASE_URI']}/a/#{circle.slug}/applications"]
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
    when :created_timetable
      'fa-table'   
    when :cultivating_quality
      'fa-star'  
    when :commented
      'fa-comment'       
    when :reacted_to_a_comment
      'fa-thumbs-up' 
    when :left_group
      'fa fa-sign-out'
    when :created_payment
      'fa-money'  
    when :created_inventory_item
      'fa-wrench'
    when :mapplication_removed
      'fa-file-text-o'
    end    
  end

        
  def self.admin_fields
    {
      :circle_type => :text,
      :circle_id => :text,
      :notifiable_type => :text,
      :notifiable_id => :text,
      :type => :text
    }
  end
    
end
