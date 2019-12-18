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

