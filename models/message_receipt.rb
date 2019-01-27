class MessageReceipt
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :messanger, class_name: "Account", inverse_of: :message_receipts_as_messanger, index: true
  belongs_to :messangee, class_name: "Account", inverse_of: :message_receipts_as_massangee, index: true
  
  validates_uniqueness_of :messanger, :scope => :messangee
  
  def self.admin_fields
    {
    	:messanger_id => :lookup,
      :messangee_id => :lookup
    }
  end
    
end
