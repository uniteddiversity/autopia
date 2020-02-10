class PsyActivityship
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "activityships", client: "psychedelicsociety"
  
  belongs_to :account, class_name: "PsyAccount", inverse_of: :psy_activityships
  belongs_to :activity, class_name: "PsyActivity", inverse_of: :psy_activities
end