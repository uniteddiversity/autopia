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
    %w{joined_team listed_spend listed_activity signed_up_to_a_shift applied joined_group joined_tier joined_transport joined_accom interested_in_activity}
  end
  
  def sentence    
    case type.to_sym
    when :joined_team
      teamship = notifiable
      account = teamship.account
      team = teamship.team
      "#{account.name} joined the #{team.name} team"
    when :listed_spend
      spend = notifiable
      account = spend.account
      "#{account.name} listed an expense"
    when :listed_activity
      activity = notifiable
      account = activity.account
      "#{account.name} listed an activity"
    when :signed_up_to_a_shift
      shift = notifiable
      rota = shift.rota
      account = shift.account
      "#{account.name} signed up for a #{rota.name} shift"
    when :applied
      mapplication = notifiable
      account = mapplication.account
      "#{account.name} applied"
    when :joined_group
      membership = notifiable
      account =  membership.account
      mapplication = membership.mapplication
      if mapplication
        if mapplication.processed_by
          "#{account.name} was accepted by #{mapplication.processed_by.name}"
        else
          "#{account.name} was automatically accepted"
        end
      else
        "#{account.name} was added"
      end
    when :joined_tier
      tiership = notifiable
      account = tiership.account
      tier = tiership.tier
      "#{account.name} joined the #{tier.name} tier"      
    when :joined_transport
      transportship = notifiable
      account = transportship.account
      transport = transportship.transport
      "#{account.name} joined the #{transport.name} transport"   
    when :joined_accom
      accomship = notifiable
      account = accomship.account
      accom = accomship.accom
      "#{account.name} joined the #{accom.name} accommodation"        
    when :interested_in_activity
      attendance = notifiable
      account = attendance.account
      activity = attendance.activity
      "#{account.name} is interested in #{activity.name}"        
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
      'fa-briefcase'
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
