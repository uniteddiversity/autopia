Autopia::App.controller do
  
  get '/activities', provides: :json do
    @activities = Activity.all.order('created_at desc')
    @activities = @activities.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    @activities = @activities.where(id: params[:id]) if params[:id]
    case content_type
    when :json
      {
        results: @activities.map { |activity| {id: activity.id.to_s, text: "#{activity.name} (id:#{activity.id})"} }
      }.to_json
    end
  end  

  get '/activities/new' do
    sign_in_required!
    @activity = Activity.new
    @activity.organisation_id = params[:organisation_id]
    erb :'activities/build'
  end
  
  post '/activities/new' do
    sign_in_required!
    @activity = Activity.new(params[:activity])
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
    @activity = Activity.find(params[:id])    
    discuss 'Activities'
    erb :'activities/activity'
  end
  
  get '/activities/:id/edit' do
    @activity = Activity.find(params[:id])
    activity_admins_only!
    discuss 'Activities'
    erb :'activities/build'
  end
  
  post '/activities/:id/edit' do
    @activity = Activity.find(params[:id])
    activity_admins_only!
    if @activity.update_attributes(params[:activity])
      redirect "/activities/#{@activity.id}"
    else
      flash[:error] = 'There was an error saving the activity.'
      discuss 'Activities'
      erb :'activities/build'
    end    
  end
  
  get '/activities/:id/feedback' do
    @activity = Activity.find(params[:id])
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
    request.xhr? ? (partial :'activities/activityship', locals: { activity: @activity, btn_class: params[:btn_class] }) : redirect("/activities/#{@activity.id}")
  end  
  
end