Huddl::App.controller do
  
  post '/h/:slug/qualities/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @quality = @group.qualities.build(params[:quality])
    @quality.account = current_account
    if @quality.save
      @quality.cultivations.create account: current_account
      redirect back
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the quality from being saved."
      erb :'qualities/qualities'
    end
  end  
  
  get '/h/:slug/qualities' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    erb :'qualities/qualities'      
  end     
  
  get '/h/:slug/qualities/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    @quality = @group.qualities.find(params[:id])
    erb :'qualities/build'
  end
  
  post '/h/:slug/qualities/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!   
    @quality = @group.qualities.find(params[:id])
    if @quality.update_attributes(params[:quality])
      redirect "/h/#{@group.slug}/qualities"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the quality from being saved." 
      erb :'qualities/build'
    end
  end  
  
  get '/h/:slug/qualities/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    @quality = @group.qualities.find(params[:id])
    @quality.destroy
    redirect "/h/#{@group.slug}/qualities"      
  end    
  
  get '/qualities/:id/cultivators' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!        
    partial :'qualities/cultivators', :locals => {:quality => @quality}
  end
    
  get '/qualities/:id/cultivate' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @quality.cultivations.create account: current_account
    200
  end     
    
  get '/qualities/:id/uncultivate' do
    @quality = Quality.find(params[:id])
    @group = @quality.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @quality.cultivations.find_by(account: current_account).try(:destroy)
    200
  end    
  
end