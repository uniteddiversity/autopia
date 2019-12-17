Autopia::App.controller do
    
  post '/a/:slug/tiers/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @tier = @gathering.tiers.build(params[:tier])
    @tier.account = current_account
    if @tier.save
      redirect "/a/#{@gathering.slug}/tiers"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the tier from being saved."
      erb :'tiers/build'    
    end
  end  
 
  get '/a/:slug/tiers' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    if request.xhr?
      partial :'tiers/tiers'
    else
      discuss 'Tiers'
      erb :'tiers/tiers'
    end
  end
  
  get '/a/:slug/tiers/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @tier = @gathering.tiers.find(params[:id])
    erb :'tiers/build'
  end
  
  post '/a/:slug/tiers/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @tier = @gathering.tiers.find(params[:id])
    if @tier.update_attributes(mass_assigning(params[:tier], Tier))
      redirect "/a/#{@gathering.slug}/tiers"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the tier from being saved." 
      erb :'tiers/build'
    end
  end  
  
  get '/a/:slug/tiers/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @tier = @gathering.tiers.find(params[:id])
    @tier.destroy
    redirect "/a/#{@gathering.slug}/tiers"      
  end     
        
  get '/tierships/create' do
    @tier = Tier.find(params[:tier_id]) || not_found
    @gathering = @tier.gathering      
    confirmed_membership_required!      
    Tiership.create(account: current_account, tier_id: params[:tier_id], gathering: @gathering)
    200
  end    
    
  get '/tierships/:id/destroy' do
    @tiership = Tiership.find(params[:id]) || not_found
    @gathering = @tiership.tier.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    halt unless @tiership.account.id == current_account.id or @membership.admin?
    @tiership.destroy
    200
  end       
    
end