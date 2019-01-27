class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body, :type => String 
  
  belongs_to :messanger, class_name: "Account", inverse_of: :messages_as_messanger, index: true
  belongs_to :messangee, class_name: "Account", inverse_of: :messages_as_massangee, index: true
    
  def self.admin_fields
    {
			:messanger_id => :lookup,
      :messangee_id => :lookup,
      :body => :text
    }
  end
  
  def self.read?(messanger, messangee)   
    messages = Message.where(messanger: messanger, messangee: messangee).order('created_at desc')
    message = messages.first
    message_receipt = MessageReceipt.find_by(messanger: messanger, messangee: messangee)    
    message && message_receipt && message_receipt.created_at > message.created_at
  end
  
  def self.unread?(messanger, messangee)
    !read?(messanger, messangee)
  end
  
  after_create :send_email  
  def send_email
    if ENV['SMTP_ADDRESS'] and !messangee.unsubscribed?
      message = self
      messanger = message.messanger      
      messangee = message.messangee
      
      mail = Mail.new
      mail.to = messangee.email
      mail.from = "#{messanger.name} <#{messanger.email}>"
      mail.subject = "Message from #{messanger.name} via Autopo"
            
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