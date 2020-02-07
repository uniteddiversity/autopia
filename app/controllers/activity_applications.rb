Autopia::App.controller do
  
  get '/activities/:id/apply' do
    @activity = Activity.find(params[:id]) || not_found
    @activityship = @activity.activityships.find_by(account: current_account)
    # redirect "/activities/#{@activity.id}/join" if @activity.privacy == 'open'        
    @account = current_account || Account.new
    erb :'activity_applications/apply'
  end
  
  post '/activities/:id/apply' do
    @activity = Activity.find(params[:id]) || not_found
    
    if account = Account.find_by(email: /^#{::Regexp.escape(params[:account][:email])}$/i)
      @account = account
      @account.update_attributes!(Hash[params[:account].map { |k,v| [k, v] if v }.compact])
    else
      @account = Account.create!(mass_assigning(params[:account], Account))
    end    
    
    if @activity.activityships.find_by(account: @account)
      flash[:notice] = "You're already part of that activity"
      redirect back
    else
      @activity_application = @activity.activity_applications.create! :account => @account, :status => 'Pending', :answers => (params[:answers].map { |i,x| [@activity.application_questions_a[i.to_i],x] } if params[:answers])
      redirect "/activities/#{@activity.id}/apply?applied=true"
    end    
  end  
  
  get '/activities/:id/applications' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!
    @activity_applications = @activity.activity_applications.order('created_at desc')
    erb :'activity_applications/applications'
  end
  
  get '/activities/:id/activity_applications/:activity_application_id' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!    
    @activity_application = @activity.activity_applications.find(params[:activity_application_id]) || not_found
    @account = @activity_application.account
    erb :'activity_applications/activity_application'
  end
  
  get '/activities/:id/activity_applications/:activity_application_id/set_status' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!    
    @activity_application = @activity.activity_applications.find(params[:activity_application_id]) || not_found
    partial :'activity_applications/set_status'
  end
  
  post '/activities/:id/activity_applications/:activity_application_id/set_status' do
    @activity = Activity.find(params[:id]) || not_found
    activity_admins_only!    
    @activity_application = @activity.activity_applications.find(params[:activity_application_id]) || not_found
    @activity_application.status = params[:status]
    @activity_application.statused_by = current_account
    @activity_application.statused_at = Time.now
    @activity_application.save
    200
  end  
  
end