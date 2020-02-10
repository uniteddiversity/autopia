
namespace :organisations do
  
  task :sync_monthly_donations => :environment do
    Organisation.where(:gocardless_access_token.ne => nil).each { |organisation|
      organisation.sync_with_gocardless
    }
    Organisation.where(:patreon_api_key.ne => nil).each { |organisation|
      organisation.sync_with_patreon
    }        
  end
  
end

namespace :events do
  
  task :delete_stale_uncompleted_orders => :environment do
    Order.incomplete.where(:created_at.lt => 1.hour.ago).destroy_all
  end
  
  task :send_feedback_requests => :environment do
    Event.where(:end_time.gte => Date.yesterday, :end_time.lt => Date.today).each { |event|
      event.send_feedback_requests
    }
  end   
  
end

