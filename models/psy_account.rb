class PsyAccount
  include Mongoid::Document
  store_in collection: "accounts", client: "psychedelicsociety"
      
  field :email, :type => String
  
  def self.admin_fields
    {
      :email => :email
    }
  end
  
  has_many :psy_activityships, class_name: 'PsyActivityship', inverse_of: :account
  
  def migrate
    p = self
     
    if account = Account.find_by(email: /^#{::Regexp.escape(p['email'])}$/i)
      puts "found #{p['account']}"
    else
      account = Account.new
      account.ps_account_id = p['id']
      account.name = p['name']
      account.email = p['email']
      account.date_of_birth = p['dob']
      account.gender = p['gender'] == 'Nonbinary' ? 'Non-binary' : p['gender']
      account.time_zone = p['time_zone']
      account.crypted_password = p['crypted_password']
      account.picture_url = "https://psychedelicsociety-s3-web.s3.amazonaws.com/#{p['picture_uid']}" if p['picture_uid']
      account.location = if (p['postcode'] && !p['country']) || (p['postcode'] && p['country' =~ /United Kingdom/])
        "#{p['postcode']}, UK"
      elsif p['country'] && p['country'] !=~ /United Kingdom/
        p['country']
      end  
      account.website = p['website']
      account.unsubscribed = p['unsubscribed']
      account.unsubscribed_feedback = p['unsubscribed_feedback']
      account.unsubscribed_messages = p['unsubscribed_messages']
      account.save!      
    end
      
    organisation = Organisation.find_by(name: 'The Psychedelic Society')
    organisationship = account.organisationships.find_by(organisation: organisation)
    if !organisationship
      organisationship = account.organisationships.build
      organisationship.organisation = organisation
      organisationship.monthly_donation_method = p['monthly_donation_method']
      organisationship.monthly_donation_amount = p['monthly_donation_amount']
      organisationship.monthly_donation_start_date = p['monthly_donation_start_date']
      organisationship.why_i_joined = p['why_i_joined']
      organisationship.why_i_joined_public = p['why_i_joined_public']
      organisationship.why_i_joined_edited = p['why_i_joined_edited']
      organisationship.save!
    end
      
    p.psy_activityships.each { |psy_activityship|
      activity = organisation.activities.find_by(name: psy_activityship.activity.name)
      activityship = account.activityships.find_by(activity: activity)
      if !activityship
        activityship = account.activityships.build
        activityship.activity = activity
        activityship.unsubscribed = psy_activityship['unsubscribed']
        activityship.save!        
      end
    }
  
  end
end