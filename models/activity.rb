class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account
  belongs_to :space
  belongs_to :tslot
  belongs_to :group
  
  field :description, :type => String
  
  validates_presence_of :account, :space, :tslot, :group
        
  def self.admin_fields
    {
      :description => :text_area,
      :account_id => :lookup,
      :space_id => :lookup,
      :tslot_id => :lookup,    
      :group_id => :lookup      
    }
  end
    
end
