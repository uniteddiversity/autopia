Autopia::App.controller do
  

  get '/local_groups/new' do
    sign_in_required!
    @local_group = LocalGroup.new
    @local_group.organisation_id = params[:organisation_id]
    erb :'local_groups/build'
  end
  
  post '/local_groups/new' do
    sign_in_required!
    @local_group = LocalGroup.new(params[:local_group])
    @local_group.account = current_account
    if @local_group.save!      
      redirect "/local_groups/#{@local_group.id}"
    else
      flash[:error] = 'There was an error saving the local group'
      discuss 'Local Groups'
      erb :'local_groups/build'
    end    
  end
  
  get '/local_groups/:id' do
    @local_group = LocalGroup.find(params[:id])    
    discuss 'Local Groups'
    erb :'local_groups/local_group'
  end
  
  get '/local_groups/:id/edit' do
    @local_group = LocalGroup.find(params[:id])
    local_group_admins_only!
    discuss 'Local Groups'
    erb :'local_groups/build'
  end
  
  post '/local_groups/:id/edit' do
    @local_group = LocalGroup.find(params[:id])
    local_group_admins_only!
    if @local_group.update_attributes(params[:local_group])
      redirect "/local_groups/#{@local_group.id}"
    else
      flash[:error] = 'There was an error saving the local group'
      discuss 'Local Groups'
      erb :'local_groups/build'
    end    
  end
  
  post '/local_groups/:id/local_groupships/admin' do    
    @local_group = LocalGroup.find(params[:id]) || not_found
    local_group_admins_only!        
    @local_groupship = @local_group.local_groupships.find_by(account_id: params[:local_groupship][:account_id]) || @local_group.local_groupships.create(account_id: params[:local_groupship][:account_id])
    @local_groupship.update_attribute(:admin, true)
    redirect back
  end  
  
  post '/local_groups/:id/local_groupships/unadmin' do    
    @local_group = LocalGroup.find(params[:id]) || not_found
    local_group_admins_only!
    @local_group.local_groupships.find_by(account_id: params[:account_id]).update_attribute(:admin, nil)
    redirect back
  end     
  
  get '/local_groups/:id/destroy' do
    @local_group = LocalGroup.find(params[:id]) || not_found
    local_group_admins_only!
    @local_group.destroy
    redirect '/local_groups/new'
  end  
  
  get '/local_groupship/:id' do
    sign_in_required!
    @local_group = LocalGroup.find(params[:id]) || not_found
    case params[:f]
    when 'not_following'
      current_account.local_groupships.find_by(local_group: @local_group).try(:destroy)
    when 'follow_without_subscribing'
      local_groupship = current_account.local_groupships.find_by(local_group: @local_group) || current_account.local_groupships.create(local_group: @local_group)
      local_groupship.update_attribute(:unsubscribed, true)
    when 'follow_and_subscribe'
      local_groupship = current_account.local_groupships.find_by(local_group: @local_group) || current_account.local_groupships.create(local_group: @local_group)
      local_groupship.update_attribute(:unsubscribed, false)
    end
    request.xhr? ? (partial :'local_groups/local_groupship', locals: { local_group: @local_group, btn_class: params[:btn_class] }) : redirect("/local_groups/#{@local_group.id}")
  end  
  
end