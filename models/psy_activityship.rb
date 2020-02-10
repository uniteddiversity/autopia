class PsyActivityship
  include Mongoid::Document
  store_in collection: "activityships", client: "psychedelicsociety"
  
  belongs_to :account, class_name: "PsyAccount", inverse_of: :psy_activityships
  belongs_to :activity, class_name: "PsyActivity", inverse_of: :psy_activities
end