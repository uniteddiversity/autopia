class OrganisationTier
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :description, :type => String
  field :threshold, :type => Integer
  field :discount, :type => Integer
  
  belongs_to :organisation, index: true
  validates_presence_of :name, :threshold, :discount
            
  def self.admin_fields
    {
      :name => :text,
      :description => :text_area,
      :threshold => :number,
      :discount => :number,
      :organisation_id => :lookup
    }
  end
      
end
