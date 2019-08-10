Autopia::App.controller do
  
  post '/a/:slug/qualities/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @quality = @gathering.qualities.build(params[:quality])
    @quality.account = current_account
    if @quality.save
      @quality.cultivations.create account: current_account
      redirect back
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the quality from being saved."
      erb :'qualities/qualities'
    end
  end  
  
  get '/a/:slug/qualities' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    discuss 'Qualities'
    erb :'qualities/qualities'      
  end     
  
  get '/a/:slug/qualities/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    @quality = @gathering.qualities.find(params[:id])
    erb :'qualities/build'
  end
  
  post '/a/:slug/qualities/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!   
    @quality = @gathering.qualities.find(params[:id])
    if @quality.update_attributes(params[:quality])
      redirect "/a/#{@gathering.slug}/qualities"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the quality from being saved." 
      erb :'qualities/build'
    end
  end  
  
  get '/a/:slug/qualities/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    @quality = @gathering.qualities.find(params[:id])
    @quality.destroy
    redirect "/a/#{@gathering.slug}/qualities"      
  end    
  
  get '/qualities/:id/cultivators' do
    @quality = Quality.find(params[:id])
    @gathering = @quality.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!        
    partial :'qualities/cultivators', :locals => {:quality => @quality}
  end
    
  get '/qualities/:id/cultivate' do
    @quality = Quality.find(params[:id])
    @gathering = @quality.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @quality.cultivations.create account: current_account
    200
  end     
    
  get '/qualities/:id/uncultivate' do
    @quality = Quality.find(params[:id])
    @gathering = @quality.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @quality.cultivations.find_by(account: current_account).try(:destroy)
    200
  end    
  
end