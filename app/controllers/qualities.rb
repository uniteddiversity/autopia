Huddl::App.controller do
  
  get '/h/:slug/qualities' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :'qualities/qualities'      
  end     

  post '/qualities/create' do
    @group = Group.find(params[:group_id]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    @quality = Quality.new(params[:quality])
    @quality.group = @group
    @quality.account = current_account
    if @quality.save
      @quality.cultivations.create account: current_account
      redirect back
    else
      flash[:error] = 'There was an error creating the quality'
      erb :'qualities/qualities'
    end
  end
  
get '/qualities/:id/edit' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    erb :'qualities/quality_build'
  end 
        
  post '/qualities/:id/edit' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    if @quality.update_attributes(params[:quality])
      redirect "/h/#{@group.slug}/qualities"
    else
      flash[:error] = 'There was an error saving the quality'
      erb :'qualities/quality_build'
    end
  end   

  get '/qualities/:id/destroy' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @quality.destroy
    redirect "/h/#{@group.slug}/qualities"
  end   
  
  get '/qualities/:id/cultivators' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!        
    partial :'qualities/cultivators', :locals => {:quality => @quality}
  end
    
  get '/qualities/:id/cultivate' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    @quality.cultivations.create account: current_account
    200
  end     
    
  get '/qualities/:id/uncultivate' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    @quality.cultivations.find_by(account: current_account).try(:destroy)
    200
  end    
  
end