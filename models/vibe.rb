class Vibe
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :viber, class_name: "Account", inverse_of: :vibes_as_viber, index: true
  belongs_to :vibee, class_name: "Account", inverse_of: :vibes_as_vibee, index: true
    
  def self.admin_fields
    {
			:viber_id => :lookup,
      :vibee_id => :lookup
    }
  end
  
  def self.vibing(a,b)
    Vibe.find_by(viber: a, vibee: b) && Vibe.find_by(viber: b, vibee: a)
  end
  
  after_create :check_if_vibing  
  def check_if_vibing
    if Vibe.vibing(viber,vibee)
      if ENV['SMTP_ADDRESS'] && !vibee.unsubscribed?
        [[viber,vibee],[vibee,viber]].each { |viber,vibee|
        
          mail = Mail.new
          mail.to = vibee.email
          mail.from = ENV['NOTIFICATION_EMAIL']
          mail.subject = "You and #{viber.name} have mutual vibes!"
            
          content = ERB.new(File.read(Padrino.root('app/views/emails/vibing.erb'))).result(binding)
          html_part = Mail::Part.new do
            content_type 'text/html; charset=UTF-8'
            body ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
          end
          mail.html_part = html_part
      
          mail.deliver
        }
      end          
    end
  end
  handle_asynchronously :check_if_vibing
    
end
