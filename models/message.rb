class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body, :type => String 
  
  belongs_to :messenger, class_name: "Account", inverse_of: :messages_as_messenger, index: true
  belongs_to :messengee, class_name: "Account", inverse_of: :messages_as_massangee, index: true
    
  def self.admin_fields
    {
			:messenger_id => :lookup,
      :messengee_id => :lookup,
      :body => :text
    }
  end
  
  after_create do
    if ENV['PUSHER_APP_ID']
      pusher_client = Pusher::Client.new(app_id: ENV['PUSHER_APP_ID'], key: ENV['PUSHER_KEY'], secret: ENV['PUSHER_SECRET'], cluster: ENV['PUSHER_CLUSTER'], encrypted: true)
      pusher_client.trigger("message.#{messenger.id}.#{messengee.id}", 'updated', {})
    end
  end
  
  def self.read?(messenger, messengee)   
    messages = Message.where(messenger: messenger, messengee: messengee).order('created_at desc')
    message = messages.first
    message_receipt = MessageReceipt.find_by(messenger: messenger, messengee: messengee)    
    message && message_receipt && message_receipt.created_at > message.created_at
  end
  
  def self.unread?(messenger, messengee)
    !read?(messenger, messengee)
  end
  
  after_create :send_email  
  def send_email
    if ENV['SMTP_ADDRESS'] and !messengee.unsubscribed_messages?
      message = self
      messenger = message.messenger      
      messengee = message.messengee
      
      mail = Mail.new
      mail.to = messengee.email
      mail.from = "#{messenger.name} <#{messenger.email}>"
      mail.subject = "Message from #{messenger.name} via Autopo"
            
      content = ERB.new(File.read(Padrino.root('app/views/emails/message.erb'))).result(binding)
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
      end
      mail.html_part = html_part
      
      mail.deliver
    end    
  end
  handle_asynchronously :send_email   
  
end