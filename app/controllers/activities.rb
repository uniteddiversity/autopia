Autopia::App.controller do
  
  get '/activities/new' do
    sign_in_required!
    @activity = Activity.new
    @activity.organisation_id = params[:organisation_id]
    erb :'activities/build'
  end
  
  post '/activities/new' do
    sign_in_required!
    @activity = Activity.new(mass_assigning(params[:activity], Activity))
    @activity.account = current_account
    if @activity.save
      redirect "/activities/#{@activity.id}"
    else
      flash[:error] = 'There was an error saving the activity'
      discuss 'Activities'
      erb :'activities/build'
    end    
  end
  
  get '/activities/:id' do
    @activity = Activity.find(params[:id]) || not_found    
    discuss 'Activities'
    erb :'activities/activity'
  end
  
  get '/activities/:id/edit' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    discuss 'Activities'
    erb :'activities/build'
  end
  
  post '/activities/:id/edit' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    if @activity.update_attributes(mass_assigning(params[:activity], Activity))
      redirect "/activities/#{@activity.id}"
    else
      flash[:error] = 'There was an error saving the activity.'
      discuss 'Activities'
      erb :'activities/build'
    end    
  end
      
  get '/activities/:id/map' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    erb :'activities/map'      
  end   
  
  get '/activities/:id/show_feedback' do
    @activity = Activity.find(params[:id]) || not_found
    partial :'activities/feedback'
  end
  
  post '/activities/:id/activityships/admin' do    
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!        
    @activityship = @activity.activityships.find_by(account_id: params[:activityship][:account_id]) || @activity.activityships.create(account_id: params[:activityship][:account_id])
    @activityship.update_attribute(:admin, true)
    redirect back
  end  
  
  post '/activities/:id/activityships/unadmin' do    
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    @activity.activityships.find_by(account_id: params[:account_id]).update_attribute(:admin, nil)
    redirect back
  end     
  
  get '/activities/:id/destroy' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    @activity.destroy
    redirect '/activities/new'
  end  
  
  get '/activityship/:id' do
    sign_in_required!
    @activity = Activity.find(params[:id]) || not_found
    if activityship = current_account.activityships.find_by(activity: @activity) || @activity.privacy == 'open'
      case params[:f]
      when 'not_following'
        current_account.activityships.find_by(activity: @activity).try(:destroy)
      when 'follow_without_subscribing'
        activityship = current_account.activityships.find_by(activity: @activity) || current_account.activityships.create(activity: @activity)
        activityship.update_attribute(:unsubscribed, true)
      when 'follow_and_subscribe'
        activityship = current_account.activityships.find_by(activity: @activity) || current_account.activityships.create(activity: @activity)
        activityship.update_attribute(:unsubscribed, false)
      end
    end
    request.xhr? ? (partial :'activities/activityship', locals: { activity: @activity, btn_class: params[:btn_class] }) : redirect("/activities/#{@activity.id}")
  end 
  
  get '/activities/:id/members' do
    @activity = Activity.find(params[:id]) || not_found
    partial :'activities/members'
  end  
  
  get '/activities/:id/hide_membership' do
    sign_in_required!
    @activity = Activity.find(params[:id]) || not_found
    @activity.activityships.find_by(account: current_account).update_attribute(:hide_membership, true)
    200
  end
  
  get '/activities/:id/show_membership' do
    sign_in_required!
    @activity = Activity.find(params[:id]) || not_found
    @activity.activityships.find_by(account: current_account).update_attribute(:hide_membership, false)
    200
  end  
  
end