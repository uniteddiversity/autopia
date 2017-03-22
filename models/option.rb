class Option
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :text, :type => String
  
  has_many :votes, :dependent => :destroy
  
  validates_presence_of :text

  belongs_to :comment, index: true
  belongs_to :account, index: true
  
  def self.admin_fields
    {
      :text => :text,
      :account_id => :lookup
    }
  end
    
end
