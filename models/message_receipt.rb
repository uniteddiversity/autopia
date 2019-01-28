class MessageReceipt
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :received_at, :type => Time
   
  belongs_to :messenger, class_name: "Account", inverse_of: :message_receipts_as_messenger, index: true
  belongs_to :messengee, class_name: "Account", inverse_of: :message_receipts_as_massangee, index: true
  
  validates_uniqueness_of :messenger, :scope => :messengee
    
  def self.admin_fields
    {
      :received_at => :datetime,
    	:messenger_id => :lookup,
      :messengee_id => :lookup
    }
  end
    
end
