namespace :groups do
  task :create_routes => :environment do
    Group.each { |group|
      group.create_route
    }
  end
end
