class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  field :file_uid, :type => String
  field :file_name, :type => String
  field :cid, :type => String
  
  belongs_to :organisation, index: true
        
  validates_presence_of :file
 
  dragonfly_accessor :file
        
  def self.admin_fields
    {
      :pmail_id => :lookup,
      :file => :file,
      :file_name => :text,
      :cid => :text
    }
  end
  
end
