Autopia::App.controller do
  
  get '/a/:slug/timetables/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @timetable = @gathering.timetables.build
    erb :'timetables/build'
  end
  
  post '/a/:slug/timetables/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @timetable = @gathering.timetables.build(params[:timetable])
    @timetable.account = current_account
    if @timetable.save
      redirect "/a/#{@gathering.slug}/timetables/#{@timetable.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the timetable from being saved."
      erb :'timetables/build'    
    end
  end  

  get '/a/:slug/timetables' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    discuss 'Timetables'
    erb :'timetables/timetables'      
  end
  
  get '/a/:slug/timetables/:id' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    @timetable = @gathering.timetables.find(params[:id]) || not_found
    confirmed_membership_required!
    if request.xhr?
      partial :'timetables/timetable', :locals => {:timetable => @timetable}
    else
      discuss 'Timetables'
      erb :'timetables/timetable'      
    end
  end  
  
  get '/a/:slug/timetables/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @timetable = @gathering.timetables.find(params[:id]) || not_found
    erb :'timetables/build'
  end
  
  post '/a/:slug/timetables/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @timetable = @gathering.timetables.find(params[:id]) || not_found
    if @timetable.update_attributes(params[:timetable])
      redirect "/a/#{@gathering.slug}/timetables/#{@timetable.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the timetable from being saved." 
      erb :'timetables/build'
    end
  end  
        
  get '/a/:slug/timetables/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @timetable = @gathering.timetables.find(params[:id]) || not_found
    @timetable.destroy
    redirect "/a/#{@gathering.slug}/timetables"      
  end    
  
  post '/spaces/order' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @gathering = @timetable.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    params[:space_ids].each_with_index { |space_id,i|
      @timetable.spaces.find(space_id).update_attribute(:o, i)
    }
    200
  end
    
  post '/spaces/create' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @gathering = @timetable.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    Space.create(name: params[:name], timetable: @timetable)
    200
  end   
    
  get '/spaces/:id/destroy' do
    @space = Space.find(params[:id]) || not_found
    @gathering = @space.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @space.destroy
    200
  end      
  
  post '/tslots/order' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @gathering = @timetable.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    params[:tslot_ids].each_with_index { |tslot_id,i|
      @timetable.tslots.find(tslot_id).update_attribute(:o, i)
    }
    200
  end  
    
  post '/tslots/create' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @gathering = @timetable.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    Tslot.create(name: params[:name], timetable: @timetable)
    200
  end      
    
  get '/tslots/:id/destroy' do
    @tslot = Tslot.find(params[:id]) || not_found
    @gathering = @tslot.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @tslot.destroy
    200  
  end    
         
  post '/tactivities/create' do
    @timetable = Timetable.find(params[:timetable_id]) || not_found
    @gathering = @timetable.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @tactivity = Tactivity.new(params[:tactivity])
    @tactivity.timetable = @timetable
    @tactivity.account = current_account
    if @tactivity.save
      redirect back
    else
      flash[:error] = 'There was an error creating the tactivity'
      erb :'timetables/timetables'
    end
  end  
  
  get '/a/:slug/tactivities/:id' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    @tactivity = @gathering.tactivities.find(params[:id])
    @timetable = @tactivity.timetable    
    confirmed_membership_required!      
    erb :'timetables/tactivity'
  end   
        
  get '/tactivities/:id/edit' do
    @tactivity = Tactivity.find(params[:id]) || not_found
    @gathering = @tactivity.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    erb :'timetables/tactivity_build'
  end 
        
  post '/tactivities/:id/edit' do
    @tactivity = Tactivity.find(params[:id]) || not_found
    @gathering = @tactivity.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    if @tactivity.update_attributes(params[:tactivity])
      redirect "/a/#{@gathering.slug}/timetables/#{@tactivity.timetable_id}"
    else
      flash[:error] = 'There was an error saving the tactivity'
      erb :'timetables/tactivity_build'
    end
  end   

  get '/tactivities/:id/destroy' do
    @tactivity = Tactivity.find(params[:id]) || not_found
    @gathering = @tactivity.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @tactivity.destroy
    redirect "/a/#{@gathering.slug}/timetables/#{@tactivity.timetable_id}"
  end 
    
  post '/tactivities/:id/schedule' do
    @tactivity = Tactivity.find(params[:id]) || not_found
    @gathering = @tactivity.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    halt unless @membership.admin? or @tactivity.timetable.scheduling_by_all
    @tactivity.tslot_id = params[:tslot_id]
    @tactivity.space_id = params[:space_id]
    @tactivity.scheduled_by = current_account
    @tactivity.save!  
    @tactivity.notifications.where(:type.in => ['scheduled_tactivity', 'unscheduled_tactivity']).destroy_all
    if @tactivity.timetable.scheduling_by_all
      @tactivity.notifications.create! :circle => @gathering, :type => 'scheduled_tactivity'   
    end
    200      
  end
    
  get '/tactivities/:id/unschedule' do
    @tactivity = Tactivity.find(params[:id]) || not_found
    @gathering = @tactivity.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    halt unless @membership.admin? or @tactivity.timetable.scheduling_by_all
    @tactivity.tslot_id = nil
    @tactivity.space_id = nil
    @tactivity.scheduled_by = current_account
    @tactivity.save!
    @tactivity.notifications.where(:type.in => ['scheduled_tactivity', 'unscheduled_tactivity']).destroy_all
    if @tactivity.timetable.scheduling_by_all
      @tactivity.notifications.create! :circle => @gathering, :type => 'unscheduled_tactivity'
    end
    200
  end  
    
  get '/tactivities/:id/attendees' do
    @tactivity = Tactivity.find(params[:id]) || not_found
    @gathering = @tactivity.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!     
    partial :'timetables/attendees', :locals => {:tactivity => @tactivity}
  end
    
  get '/tactivities/:id/attend' do
    @tactivity = Tactivity.find(params[:id]) || not_found
    @gathering = @tactivity.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @tactivity.attendances.create account: current_account
    request.xhr? ? 200 : redirect(back)
  end     
    
  get '/tactivities/:id/unattend' do
    @tactivity = Tactivity.find(params[:id]) || not_found
    @gathering = @tactivity.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @tactivity.attendances.find_by(account: current_account).try(:destroy)
    request.xhr? ? 200 : redirect(back)
  end       
    
end