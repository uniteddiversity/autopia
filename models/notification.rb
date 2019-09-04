class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, type: String

  belongs_to :circle, polymorphic: true, index: true
  belongs_to :notifiable, polymorphic: true, index: true

  def self.circle_types
    %w[Gathering Account]
  end

  def circle_url
    if circle.is_a?(Gathering)
      "#{ENV['BASE_URI']}/a/#{circle.slug}"
    elsif circle.is_a?(Account)
      "#{ENV['BASE_URI']}/accounts/#{circle.id}"
    end
  end

  validates_presence_of :type

  before_validation do
    errors.add(:type, 'not found') unless Notification.types.include?(type)
  end

  def self.types
    %w[created_gathering applied joined_gathering created_team created_timetable created_activity created_rota created_tier created_accom created_transport created_spend created_room created_place updated_profile updated_place followed completed_a_habit liked_a_habit_completion joined_team signed_up_to_a_shift interested_in_activity scheduled_activity unscheduled_activity made_admin unadmined cultivating_quality commented reacted_to_a_comment left_gathering created_payment created_inventory_item mapplication_removed]
  end

  def self.mailable_types
    %w[created_gathering created_team created_timetable created_activity created_rota created_tier created_accom created_transport created_spend created_room created_place]
  end

  after_create :send_email
  def send_email
    if ENV['SMTP_ADDRESS'] && Notification.mailable_types.include?(type)
      notification = self
      circle = self.circle
      bcc = circle.emails

      unless bcc.empty?
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
    when :created_gathering
      gathering = notifiable
      "<strong>#{gathering.account.name}</strong> created the gathering"
    when :applied
      mapplication = notifiable
      "<strong>#{mapplication.account.name}</strong> applied"
    when :joined_gathering
      membership = notifiable
      mapplication = membership.mapplication
      if mapplication
        if mapplication.processed_by
          "<strong>#{membership.account.name}</strong> was accepted by <strong>#{mapplication.processed_by.name}</strong>"
        else
          "<strong>#{membership.account.name}</strong> was accepted"
        end
      elsif membership.added_by
        "<strong>#{membership.account.name}</strong> was added by #{membership.added_by.name}"
      else
        "<strong>#{membership.account.name}</strong> joined the gathering"
      end
    when :joined_team
      teamship = notifiable
      "<strong>#{teamship.account.name}</strong> joined the <strong>#{teamship.team.name}</strong> team"
    when :followed
      follow = notifiable
      "<strong>#{follow.follower.name}</strong> followed <strong>#{follow.followee.name}</strong>"
    when :completed_a_habit
      habit_completion = notifiable
      "<strong>#{habit_completion.account.name}</strong> completed the habit <strong>#{habit_completion.habit.name}</strong>"
    when :liked_a_habit_completion
      habit_completion_like = notifiable
      "<strong>#{habit_completion_like.account.name}</strong> liked <strong>#{habit_completion_like.habit.account.name}</strong>'s completion of <strong>#{habit_completion_like.habit.name}</strong>"
    when :created_spend
      spend = notifiable
      "<strong>#{spend.account.name}</strong> spent #{spend.gathering.currency_symbol}#{spend.amount} on <strong>#{spend.item}</strong>"
    when :created_room
      room = notifiable
      "<strong>#{room.account.name}</strong> listed the room <strong>#{room.name}</strong>"
    when :created_place
      place = notifiable
      "<strong>#{place.account.name}</strong> listed the place <strong>#{place.name}</strong>"
    when :updated_profile
      account = notifiable
      "<strong>#{account.name}</strong> updated their profile"
    when :updated_place
      place = notifiable
      "<strong>#{place.name}</strong> was updated"
    when :created_activity
      activity = notifiable
      "<strong>#{activity.account.name}</strong> proposed the activity <strong>#{activity.name}</strong> under <strong>#{activity.timetable.name}</strong>"
    when :signed_up_to_a_shift
      shift = notifiable
      "<strong>#{shift.account.name}</strong> signed up for a <strong>#{shift.rota.name}</strong> shift"
    when :interested_in_activity
      attendance = notifiable
      "<strong>#{attendance.account.name}</strong> is interested in <strong>#{attendance.activity.name}</strong>"
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
      elsif comment.commentable.is_a?(Photo)
        if comment.first_in_post?
          "<strong>#{comment.account.name}</strong> started a thread <strong>#{comment.commentable.photoable.name}#{if comment.post.subject; "/#{comment.post.subject}"; end}</strong>"
        else
          "<strong>#{comment.account.name}</strong> replied to <strong>#{comment.commentable.photoable.name}#{if comment.post.subject; "/#{comment.post.subject}"; end}</strong>"
        end        
      elsif comment.commentable.is_a?(Habit)
        if comment.first_in_post?
          "<strong>#{comment.account.name}</strong> started a thread <strong>#{comment.commentable.account.name}/#{comment.commentable.name}#{if comment.post.subject; "/#{comment.post.subject}"; end}</strong>"
        else
          "<strong>#{comment.account.name}</strong> replied to <strong>#{comment.commentable.account.name}/#{comment.commentable.name}#{if comment.post.subject; "/#{comment.post.subject}"; end}</strong>"
        end
      elsif comment.commentable.is_a?(Account)
        if comment.first_in_post?
          if comment.post.subject
            "<strong>#{comment.account.name}</strong> started a thread <strong>#{comment.post.subject}</strong>"  
          else
            "<strong>#{comment.account.name}</strong> started a thread"  
          end
        else
          if comment.post.subject
            "<strong>#{comment.account.name}</strong> replied to <strong>#{comment.post.subject}</strong>"
          else
            "<strong>#{comment.account.name}</strong> replied"
          end
        end
      else
        if comment.first_in_post?
          "<strong>#{comment.account.name}</strong> started a thread <strong>#{comment.commentable.name}#{if comment.post.subject; "/#{comment.post.subject}"; end}</strong>"
        else
          "<strong>#{comment.account.name}</strong> replied to <strong>#{comment.commentable.name}#{if comment.post.subject; "/#{comment.post.subject}"; end}</strong>"
        end
      end
    when :reacted_to_a_comment
      comment_reaction = notifiable
      if comment_reaction.commentable.is_a?(Account)
        if comment_reaction.comment.post.subject
          "<strong>#{comment_reaction.account.name}</strong> reacted with #{comment_reaction.body} to <strong>#{comment_reaction.comment.account.name}'s</strong> comment in <strong>#{comment_reaction.comment.post.subject}</strong>"
        else
          "<strong>#{comment_reaction.account.name}</strong> reacted with #{comment_reaction.body} to <strong>#{comment_reaction.comment.account.name}'s</strong> comment"
        end
      elsif comment_reaction.commentable.is_a?(Photo)
        if comment_reaction.comment.post.subject
          "<strong>#{comment_reaction.account.name}</strong> reacted with #{comment_reaction.body} to <strong>#{comment_reaction.comment.account.name}'s</strong> comment in <strong>#{comment_reaction.comment.post.subject}</strong>"
        else
          "<strong>#{comment_reaction.account.name}</strong> reacted with #{comment_reaction.body} to <strong>#{comment_reaction.comment.account.name}'s</strong> comment"
        end        
      else
        if comment_reaction.comment.post.subject
          "<strong>#{comment_reaction.account.name}</strong> reacted with #{comment_reaction.body} to <strong>#{comment_reaction.comment.account.name}'s</strong> comment in <strong>#{comment_reaction.commentable.name}/#{comment_reaction.comment.post.subject}</strong>"
        else
          "<strong>#{comment_reaction.account.name}</strong> reacted with #{comment_reaction.body} to <strong>#{comment_reaction.comment.account.name}'s</strong> comment in <strong>#{comment_reaction.commentable.name}"
        end
      end
    when :left_gathering
      account = notifiable
      "<strong>#{account.name}</strong> is no longer a member"
    when :created_payment
      payment = notifiable
      "<strong>#{payment.account.name}</strong> made a payment of #{Gathering.currency_symbol(payment.currency)}#{payment.amount}"
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
    when :created_gathering
      ['View gathering', "#{ENV['BASE_URI']}/a/#{circle.slug}"]
    when :applied
      ['View applications', "#{ENV['BASE_URI']}/a/#{circle.slug}/applications"]
    when :joined_gathering
      ['View members', "#{ENV['BASE_URI']}/a/#{circle.slug}/members"]
    when :joined_team
      ['View team', "#{ENV['BASE_URI']}/a/#{circle.slug}/teams/#{notifiable.team_id}"]
    when :followed
      ['View profile', "#{ENV['BASE_URI']}/u/#{notifiable.followee.username}"]
    when :completed_a_habit
      ['View habit', "#{ENV['BASE_URI']}/habits/#{notifiable.habit.id}"]
    when :liked_a_habit_completion
      ['View habit', "#{ENV['BASE_URI']}/habits/#{notifiable.habit.id}"]
    when :created_spend
      ['View budget', "#{ENV['BASE_URI']}/a/#{circle.slug}/budget"]
    when :created_room
      ['View room', "#{ENV['BASE_URI']}/rooms/#{notifiable.id}"]
    when :created_place
      ['View place', "#{ENV['BASE_URI']}/places/#{notifiable.id}"]
    when :updated_profile
      ['View profile', "#{ENV['BASE_URI']}/u/#{notifiable.username}"]
    when :updated_place
      ['View place', "#{ENV['BASE_URI']}/places/#{notifiable.id}"]
    when :created_activity
      ['View activity', "#{ENV['BASE_URI']}/a/#{circle.slug}/activities/#{notifiable.id}"]
    when :signed_up_to_a_shift
      ['View rotas', "#{ENV['BASE_URI']}/a/#{circle.slug}/rotas/#{notifiable.rota_id}"]
    when :interested_in_activity
      ['View activity', "#{ENV['BASE_URI']}/a/#{circle.slug}/activities/#{notifiable.activity_id}"]
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
      ['View activity', "#{ENV['BASE_URI']}/a/#{circle.slug}/activities/#{notifiable.id}"]
    when :unscheduled_activity
      ['View activity', "#{ENV['BASE_URI']}/a/#{circle.slug}/activities/#{notifiable.id}"]
    when :made_admin
      ['View members', "#{ENV['BASE_URI']}/a/#{circle.slug}/members"]
    when :unadmined
      ['View members', "#{ENV['BASE_URI']}/a/#{circle.slug}/members"]
    when :created_timetable
      ['View timetable', "#{ENV['BASE_URI']}/a/#{circle.slug}/timetables/#{notifiable.id}"]
    when :cultivating_quality
      ['View qualities', "#{ENV['BASE_URI']}/a/#{circle.slug}/qualities"]
    when :commented
      ['View post', notifiable.post.url]
    when :reacted_to_a_comment
      ['View post', notifiable.post.url]
    when :left_gathering
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
    when :created_gathering
      'fa-group'
    when :applied
      'fa-file-text-o'
    when :joined_gathering
      'fa-user-plus'
    when :joined_team
      'fa-group'
    when :followed
      'fa-user-plus'
    when :completed_a_habit
      'fa-check'
    when :liked_a_habit_completion
      'fa-thumbs-up'
    when :created_spend
      'fa-money'
    when :created_room
      'fa-cube'
    when :created_place
      'fa-map-marker'
    when :updated_profile
      'fa-user-circle-o'
    when :updated_place
      'fa-map-marker'
    when :created_activity
      'fa-paper-plane'
    when :signed_up_to_a_shift
      'fa-hand-paper-o'
    when :interested_in_activity
      'fa-thumbs-up'
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
    when :left_gathering
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
      circle_type: :text,
      circle_id: :text,
      notifiable_type: :text,
      notifiable_id: :text,
      type: :text
    }
  end
end
