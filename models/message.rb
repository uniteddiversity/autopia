class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body, :type => String 
  
  validates_presence_of :body
  
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
      pusher_client.trigger("message.#{messengee.id}.#{messenger.id}", 'updated', {})
    end
  end
  
  def self.read?(messenger, messengee)   
    messages = Message.where(messenger: messenger, messengee: messengee).order('created_at desc')
    message = messages.first
    message_receipt = MessageReceipt.find_by(messenger: messenger, messengee: messengee)    
    message && message_receipt && message_receipt.received_at > message.created_at
  end
  
  def self.unread?(messenger, messengee)
    !read?(messenger, messengee)
  end
  
  after_create :send_email  
  def send_email
    if !messengee.unsubscribed? && !messengee.unsubscribed_messages?     
      mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']
      batch_message = Mailgun::BatchMessage.new(mg_client, ENV['MAILGUN_DOMAIN'])
    
      message = self
      messenger = message.messenger      
      messengee = message.messengee
      content = ERB.new(File.read(Padrino.root('app/views/emails/message.erb'))).result(binding)
      batch_message.from "#{messenger.name} <#{messenger.email}>"
      batch_message.subject "[Autopia] Message from #{messenger.name}"
      batch_message.body_html ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)
                
      [messengee].each { |account|
        batch_message.add_recipient(:to, account.email, {'firstname' => (account.firstname || 'there'), 'token' => account.sign_in_token, 'id' => account.id})
      }      

      batch_message.finalize
    end    
  end
  handle_asynchronously :send_email   
  
end