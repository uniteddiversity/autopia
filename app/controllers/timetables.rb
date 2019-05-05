Autopia::App.controller do
  
  get '/a/:slug/timetables/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @timetable = @group.timetables.build
    erb :'timetables/build'
  end
  
  post '/a/:slug/timetables/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @timetable = @group.timetables.build(params[:timetable])
    @timetable.account = current_account
    if @timetable.save
      redirect "/a/#{@group.slug}/timetables/#{@timetable.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the timetable from being saved."
      erb :'timetables/build'    
    end
  end  

  get '/a/:slug/timetables' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    discuss 'Timetables'
    erb :'timetables/timetables'      
  end
  
  get '/a/:slug/timetables/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @timetable = @group.timetables.find(params[:id])
    confirmed_membership_required!
    if request.xhr?
      partial :'timetables/timetable', :locals => {:timetable => @timetable}
    else
      discuss 'Timetables'
      erb :'timetables/timetable'      
    end
  end  
  
  get '/a/:slug/timetables/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!    
    @timetable = @group.timetables.find(params[:id])
    erb :'timetables/build'
  end
  
  post '/a/:slug/timetables/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!    
    @timetable = @group.timetables.find(params[:id])
    if @timetable.update_attributes(params[:timetable])
      redirect "/a/#{@group.slug}/timetables/#{@timetable.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the timetable from being saved." 
      erb :'timetables/build'
    end
  end  
        
  get '/a/:slug/timetables/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!    
    @timetable = @group.timetables.find(params[:id])
    @timetable.destroy
    redirect "/a/#{@group.slug}/timetables"      
  end    
  
  post '/spaces/order' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @group = @timetable.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    params[:space_ids].each_with_index { |space_id,i|
      @timetable.spaces.find(space_id).update_attribute(:o, i)
    }
    200
  end
    
  post '/spaces/create' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @group = @timetable.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Space.create(name: params[:name], timetable: @timetable)
    200
  end   
    
  get '/spaces/:id/destroy' do
    @space = Space.find(params[:id]) || not_found
    @group = @space.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @space.destroy
    200
  end      
  
  post '/tslots/order' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @group = @timetable.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    params[:tslot_ids].each_with_index { |tslot_id,i|
      @timetable.tslots.find(tslot_id).update_attribute(:o, i)
    }
    200
  end  
    
  post '/tslots/create' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @group = @timetable.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Tslot.create(name: params[:name], timetable: @timetable)
    200
  end      
    
  get '/tslots/:id/destroy' do
    @tslot = Tslot.find(params[:id]) || not_found
    @group = @tslot.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @tslot.destroy
    200  
  end    
         
  post '/activities/create' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @group = @timetable.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @activity = Activity.new(params[:activity])
    @activity.timetable = @timetable
    @activity.account = current_account
    if @activity.save
      redirect back
    else
      flash[:error] = 'There was an error creating the activity'
      erb :'timetables/timetables'
    end
  end  
  
  get '/a/:slug/activities/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @activity = @group.activities.find(params[:id])
    @timetable = @activity.timetable    
    confirmed_membership_required!      
    erb :'timetables/activity'
  end   
        
  get '/activities/:id/edit' do
    @activity = Activity.find(params[:id]) || not_found
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    erb :'timetables/activity_build'
  end 
        
  post '/activities/:id/edit' do
    @activity = Activity.find(params[:id]) || not_found
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    if @activity.update_attributes(params[:activity])
      redirect "/a/#{@group.slug}/timetables/#{@activity.timetable_id}"
    else
      flash[:error] = 'There was an error saving the activity'
      erb :'timetables/activity_build'
    end
  end   

  get '/activities/:id/destroy' do
    @activity = Activity.find(params[:id]) || not_found
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @activity.destroy
    redirect "/a/#{@group.slug}/timetables/#{@activity.timetable_id}"
  end 
    
  post '/activities/:id/schedule' do
    @activity = Activity.find(params[:id]) || not_found
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    halt unless @membership.admin? or @activity.timetable.scheduling_by_all
    @activity.tslot_id = params[:tslot_id]
    @activity.space_id = params[:space_id]
    @activity.scheduled_by = current_account
    @activity.save!  
    @activity.notifications.where(:type.in => ['scheduled_activity', 'unscheduled_activity']).destroy_all
    if @activity.timetable.scheduling_by_all
      @activity.notifications.create! :circle => @group, :type => 'scheduled_activity'   
    end
    200      
  end
    
  get '/activities/:id/unschedule' do
    @activity = Activity.find(params[:id]) || not_found
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    halt unless @membership.admin? or @activity.timetable.scheduling_by_all
    @activity.tslot_id = nil
    @activity.space_id = nil
    @activity.scheduled_by = current_account
    @activity.save!
    @activity.notifications.where(:type.in => ['scheduled_activity', 'unscheduled_activity']).destroy_all
    if @activity.timetable.scheduling_by_all
      @activity.notifications.create! :circle => @group, :type => 'unscheduled_activity'
    end
    200
  end  
    
  get '/activities/:id/attendees' do
    @activity = Activity.find(params[:id]) || not_found
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!     
    partial :'timetables/attendees', :locals => {:activity => @activity}
  end
    
  get '/activities/:id/attend' do
    @activity = Activity.find(params[:id]) || not_found
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @activity.attendances.create account: current_account
    request.xhr? ? 200 : redirect(back)
  end     
    
  get '/activities/:id/unattend' do
    @activity = Activity.find(params[:id]) || not_found
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @activity.attendances.find_by(account: current_account).try(:destroy)
    request.xhr? ? 200 : redirect(back)
  end       
    
end