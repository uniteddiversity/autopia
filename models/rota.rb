class Rota
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :description, :type => String
 
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  validates_presence_of :name, :group
  
  has_many :roles, :dependent => :destroy
  has_many :rslots, :dependent => :destroy
  has_many :shifts, :dependent => :destroy
  
  has_many :notifications, as: :notifiable, dependent: :destroy
  after_create do
    notifications.create! :circle => group, :type => 'created_rota'
  end        
   
  def self.admin_fields
    {
      :name => :text,
      :description => :wysiwyg,
      :group_id => :lookup,
      :account_id => :lookup,
      :roles => :collection,
      :rslots => :collection,
      :shifts => :collection
    }
  end
    
end
