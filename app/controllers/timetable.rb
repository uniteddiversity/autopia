Huddl::App.controller do

  get '/h/:slug/timetable' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :timetable      
  end
    
  post '/spaces/create' do
    @group = Group.find(params[:group_id]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Space.create(name: params[:name], group: @group)
    redirect back
  end   
    
  get '/spaces/:id/destroy' do
    @space = Space.find(params[:id]) || not_found
    @group = @space.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @space.destroy
    redirect back      
  end      
    
  post '/tslots/create' do
    @group = Group.find(params[:group_id]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Tslot.create(name: params[:name], group: @group)
    redirect back
  end      
    
  get '/tslots/:id/destroy' do
    @tslot = Tslot.find(params[:id]) || not_found
    @group = @tslot.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @tslot.destroy
    redirect back      
  end    
         
  post '/activities/create' do
    @group = Group.find(params[:group_id]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    @activity = Activity.new(params[:activity])
    @activity.group = @group
    @activity.account = current_account
    if @activity.save
      redirect back
    else
      flash[:error] = 'There was an error creating the activity'
      erb :timetable
    end
  end  
    
  get '/activities/:id' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required! 
    partial :activity_desc, :locals => {:activity => @activity}
  end
    
  get '/activities/:id/edit' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    erb :edit_activity
  end 
        
  post '/activities/:id/edit' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    if @activity.update_attributes(params[:activity])
      redirect "/h/#{@group.slug}/timetable"
    else
      flash[:error] = 'There was an error saving the activity'
      erb :edit_activity
    end
  end   

  get '/activities/:id/destroy' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @activity.destroy
    redirect "/h/#{@group.slug}/timetable"
  end 
    
  post '/activities/:id/schedule' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
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
    @activity.tslot_id = nil
    @activity.space_id = nil
    @activity.scheduled_by = current_account
    @activity.save!
    @activity.notifications.where(:type.in => ['scheduled_activity', 'unscheduled_activity']).destroy_all
    @activity.notifications.create! :group => @group, :type => 'unscheduled_activity'
    redirect back
  end  
    
  get '/activities/:id/attendees' do
    @activity = Activity.find(params[:id])
    @group = @activity.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!        
    partial :attendees, :locals => {:activity => @activity}
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