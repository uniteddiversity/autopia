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
  
end