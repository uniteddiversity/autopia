Huddl::App.controller do

  get '/h/:slug/timetables' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :'timetables/timetables'      
  end
  
  get '/h/:slug/timetables/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @timetable = @group.timetables.find(params[:id])
    membership_required!
    if request.xhr?
      partial :'timetables/timetable', :locals => {:timetable => @timetable}
    else
      erb :'timetables/timetable'      
    end
  end  
  
  post '/timetables/create' do
    @group = Group.find(params[:group_id]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @timetable = Timetable.create(name: params[:name], group: @group, account: current_account)
    redirect "/h/#{@group.slug}/timetables/#{@timetable.id}"
  end
    
  get '/timetables/:id/destroy' do
    @timetable = Timetable.find(params[:id]) || not_found
    @group = @timetable.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @timetable.destroy
    redirect "/h/#{@group.slug}/timetables"  
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
    membership_required!      
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
        
  get '/activities/:id/edit' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    erb :'timetables/activity_build'
  end 
        
  post '/activities/:id/edit' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    if @activity.update_attributes(params[:activity])
      redirect "/h/#{@group.slug}/timetables/#{@activity.timetable_id}"
    else
      flash[:error] = 'There was an error saving the activity'
      erb :'timetables/activity_build'
    end
  end   

  get '/activities/:id/destroy' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @activity.destroy
    redirect "/h/#{@group.slug}/timetables/#{@activity.timetable_id}"
  end 
    
  post '/activities/:id/schedule' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    halt unless @membership.admin? or @group.scheduling_by_all
    @activity.tslot_id = params[:tslot_id]
    @activity.space_id = params[:space_id]
    @activity.scheduled_by = current_account
    @activity.save!
    @activity.notifications.where(:type.in => ['scheduled_activity', 'unscheduled_activity']).destroy_all
    @activity.notifications.create! :group => @group, :type => 'scheduled_activity'   
    200      
  end
    
  get '/activities/:id/unschedule' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!    
    halt unless @membership.admin? or @group.scheduling_by_all
    @activity.tslot_id = nil
    @activity.space_id = nil
    @activity.scheduled_by = current_account
    @activity.save!
    @activity.notifications.where(:type.in => ['scheduled_activity', 'unscheduled_activity']).destroy_all
    @activity.notifications.create! :group => @group, :type => 'unscheduled_activity'
    200
  end  
    
  get '/activities/:id/attendees' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!        
    partial :'timetables/attendees', :locals => {:activity => @activity}
  end
    
  get '/activities/:id/attend' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    @activity.attendances.create account: current_account
    200
  end     
    
  get '/activities/:id/unattend' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    @activity.attendances.find_by(account: current_account).try(:destroy)
    200
  end       
    
end