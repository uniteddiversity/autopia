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
    @activity.promoter_id = params[:promoter_id]
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
  
  post '/activities/:id/activity_facilitations/new' do    
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    @activity.activity_facilitations.create(account_id: params[:activity_facilitation][:account_id])
    redirect back
  end    
  
  post '/activities/:id/activity_facilitations/destroy' do    
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    @activity.activity_facilitations.find_by(account_id: params[:account_id]).destroy
    redirect back
  end     
  
  get '/activities/:id/destroy' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    @activity.destroy
    redirect '/activities/new'
  end  
  
end