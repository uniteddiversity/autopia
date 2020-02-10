class PsyActivity
  include Mongoid::Document
  store_in collection: "activities", client: "psychedelicsociety"
  
  field :name, :type => String
  
  has_many :psy_activityships, class_name: 'PsyActivityship', inverse_of: :activity
  
  def migrate
    a = self
     
    organisation = Organisation.find_by(name: 'The Psychedelic Society')
    activity = organisation.activities.find_by(name: a['name'])
    if !activity
      activity = organisation.activities.build
      activity.name = a['name']
      activity.email = a['email']
      activity.website = a['link']
      activity.image_url = "https://psychedelicsociety-s3-web.s3.amazonaws.com/#{a['image_uid']}" if a['image_uid']
      activity.vat_category = a['vat_category']
      activity.save!
    end    
  end
  
end